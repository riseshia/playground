#!/usr/bin/env node

// LongMemEval Benchmark Runner
// Processes each question independently: ingest → search → answer → evaluate
// Intermediate results are saved per-question under output/questions/<id>/
//
// Usage:
//   node run.mjs              Run full pipeline
//   node run.mjs download     Download dataset only
//   node run.mjs --resume     Resume from last checkpoint
//   node run.mjs --limit N    Process only N questions (for testing)
//   node run.mjs --question ID[,ID,...]  Process specific question(s) only
//
// Prerequisites:
//   claude CLI           Required for ingest/search/answer
//   OPENROUTER_API_KEY   Required for evaluate

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { resolve } from 'path';
import { ingest } from './ingest.mjs';
import { search } from './search.mjs';
import { answer } from './answer.mjs';
import { evaluate } from './evaluate.mjs';

// ─── Config ─────────────────────────────────────────────────────────

const HF_BASE = 'https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned/resolve/main';
const FILES = {
  's_cleaned': { url: `${HF_BASE}/longmemeval_s_cleaned.json`, path: 'data/longmemeval_s_cleaned.json', size: '277MB' },
  'oracle': { url: `${HF_BASE}/longmemeval_oracle.json`, path: 'data/longmemeval_oracle.json', size: '15MB' },
};

const RESULTS_FILE = 'output/results.jsonl';
const QUESTIONS_DIR = 'output/questions';
const CONCURRENCY = 3;

// ─── Helpers ────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { command: 'run', limit: 0, resume: false, questionIds: [] };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === 'download') opts.command = 'download';
    if (args[i] === '--limit' && args[i + 1]) opts.limit = parseInt(args[i + 1], 10);
    if (args[i] === '--resume') opts.resume = true;
    if (args[i] === '--question' && args[i + 1]) {
      opts.questionIds = args[i + 1].split(',').map(s => s.trim());
    }
  }
  return opts;
}

function download() {
  mkdirSync('data', { recursive: true });
  for (const [name, file] of Object.entries(FILES)) {
    if (existsSync(file.path)) {
      console.log(`  ✓ ${name} (${file.path})`);
      continue;
    }
    console.log(`  ↓ ${name} (${file.size})...`);
    try {
      execSync(`curl -sL -o "${file.path}" "${file.url}"`, { stdio: 'inherit', timeout: 600000 });
      console.log(`  ✓ ${name} → ${file.path}`);
    } catch (err) {
      console.error(`  ✗ Failed: ${err.message}`);
      process.exit(1);
    }
  }
}

function questionDir(questionId) {
  return `${QUESTIONS_DIR}/${questionId}`;
}

function loadProcessedIds() {
  if (!existsSync(RESULTS_FILE)) return new Set();
  return new Set(
    readFileSync(RESULTS_FILE, 'utf-8')
      .split('\n')
      .filter(Boolean)
      .map(line => { try { return JSON.parse(line).question_id; } catch { return null; } })
      .filter(Boolean)
  );
}

/**
 * Process a single question: ingest its haystack → search → answer → evaluate
 * Intermediate results are cached in output/questions/<id>/
 */
async function processQuestion(question) {
  const dir = questionDir(question.question_id);
  mkdirSync(dir, { recursive: true });

  const factsFile = `${dir}/facts.jsonl`;
  const searchFile = `${dir}/search.json`;
  const resultFile = `${dir}/result.json`;

  const qid = question.question_id;
  const log = (msg) => process.stderr.write(`  [${qid}] ${msg}\n`);

  // 1. Ingest
  let facts;
  if (existsSync(factsFile)) {
    facts = readFileSync(factsFile, 'utf-8').split('\n').filter(Boolean).map(l => JSON.parse(l));
    log(`ingest: cached (${facts.length} facts)`);
  } else {
    const sessions = question.haystack_session_ids.map((id, i) => ({
      id,
      messages: question.haystack_sessions[i],
      date: question.haystack_dates[i],
    }));
    facts = await ingest(sessions, { log });
    writeFileSync(factsFile, facts.map(f => JSON.stringify(f)).join('\n') + '\n');
  }

  // 2. Search (always re-run)
  log('search...');
  const retrieved = await search(question.question, facts, resolve(factsFile));
  writeFileSync(searchFile, JSON.stringify(retrieved, null, 2));
  log(`search: done (${retrieved.length} results)`);

  // 3. Answer
  log('answer...');
  const hypothesis = await answer(question.question, retrieved);
  log('answer: done');

  // 4. Evaluate
  log('evaluate...');
  const { label, judgeResponse } = await evaluate({
    questionType: question.question_type,
    questionId: question.question_id,
    question: question.question,
    answer: question.answer,
    hypothesis,
  });

  const result = {
    question_id: question.question_id,
    question_type: question.question_type,
    question: question.question,
    expected: question.answer,
    hypothesis,
    label,
    judge_response: judgeResponse,
    facts_extracted: facts.length,
    facts_retrieved: retrieved.length,
  };

  writeFileSync(resultFile, JSON.stringify(result, null, 2));
  return result;
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs();

  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  LongMemEval Benchmark — ASMR-lite (JSONL + grep)  ║');
  console.log('╚══════════════════════════════════════════════════════╝');
  console.log();

  // Check environment
  if (opts.command === 'run') {
    if (!process.env.OPENROUTER_API_KEY) {
      console.error('Error: OPENROUTER_API_KEY not set (required for evaluate stage)');
      process.exit(1);
    }
  }

  // Download
  if (opts.command === 'download' || opts.command === 'run') {
    console.log('Dataset:');
    download();
    if (opts.command === 'download') {
      console.log('\nDone. Run `node run.mjs` to start.');
      return;
    }
  }

  mkdirSync('output', { recursive: true });
  mkdirSync(QUESTIONS_DIR, { recursive: true });

  // Load dataset
  console.log('\nLoading dataset...');
  const dataset = JSON.parse(readFileSync(FILES.s_cleaned.path, 'utf-8'));
  console.log(`  ${dataset.length} questions loaded`);

  let toProcess = [...dataset];
  const isTargeted = opts.questionIds.length > 0;

  // Filter by specific question IDs
  if (isTargeted) {
    const idSet = new Set(opts.questionIds);
    toProcess = toProcess.filter(q => idSet.has(q.question_id));
    console.log(`  Filtered to ${toProcess.length} question(s): ${opts.questionIds.join(', ')}`);
  }

  if (opts.resume && !isTargeted) {
    const done = loadProcessedIds();
    const before = toProcess.length;
    toProcess = toProcess.filter(q => !done.has(q.question_id));
    console.log(`  Resuming: ${before - toProcess.length} done, ${toProcess.length} remaining`);
  }

  if (opts.limit > 0) {
    toProcess = toProcess.slice(0, opts.limit);
    console.log(`  Limited to ${toProcess.length} questions`);
  }

  if (toProcess.length === 0) {
    console.log('\nNothing to process.');
    return;
  }

  // For targeted runs, force re-process (answer + evaluate) but reuse cached facts/search
  // For full runs, only reset results file on fresh start
  if (!opts.resume && !isTargeted) {
    writeFileSync(RESULTS_FILE, '');
  }

  console.log(`\nProcessing ${toProcess.length} questions...\n`);
  const startTime = Date.now();
  let correct = 0;
  let total = 0;

  for (let i = 0; i < toProcess.length; i += CONCURRENCY) {
    const batch = toProcess.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(q => processQuestion(q))
    );

    for (let j = 0; j < results.length; j++) {
      const r = results[j];
      total++;
      if (r.status === 'fulfilled') {
        if (r.value.label) correct++;
        appendFileSync(RESULTS_FILE, JSON.stringify(r.value) + '\n');
      } else {
        console.error(`  ✗ Error: ${r.reason?.message || r.reason}`);
        appendFileSync(RESULTS_FILE, JSON.stringify({
          question_id: batch[j]?.question_id || 'unknown',
          label: false,
          error: r.reason?.message || String(r.reason),
        }) + '\n');
      }
    }

    const done = Math.min(i + CONCURRENCY, toProcess.length);
    const pct = Math.round(done / toProcess.length * 100);
    const acc = total > 0 ? (correct / total * 100).toFixed(1) : '0.0';
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
    const eta = total > 0 ? ((Date.now() - startTime) / total * (toProcess.length - done) / 1000 / 60).toFixed(1) : '?';
    process.stderr.write(`\r  [${pct}%] ${done}/${toProcess.length} | accuracy: ${acc}% | ${elapsed}s elapsed | ~${eta}min remaining`);
  }

  const totalTime = ((Date.now() - startTime) / 1000 / 60).toFixed(1);
  console.log(`\n\n✓ Done in ${totalTime} minutes`);
  console.log(`  Results → ${RESULTS_FILE}\n`);

  // Auto-run report
  execSync('node report.mjs', { stdio: 'inherit' });
}

main().catch(err => {
  console.error('\nFatal:', err.message);
  process.exit(1);
});
