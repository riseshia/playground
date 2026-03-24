#!/usr/bin/env node

// LongMemEval Benchmark Runner
// Processes each question independently: ingest → search → answer → evaluate
//
// Usage:
//   node run.mjs              Run full pipeline
//   node run.mjs download     Download dataset only
//   node run.mjs --resume     Resume from last checkpoint
//   node run.mjs --limit N    Process only N questions (for testing)
//
// Prerequisites:
//   claude CLI           Required for ingest/search/answer
//   OPENROUTER_API_KEY   Required for evaluate

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
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
const CONCURRENCY = 3;

// ─── Helpers ────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { command: 'run', limit: 0, resume: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === 'download') opts.command = 'download';
    if (args[i] === '--limit' && args[i + 1]) opts.limit = parseInt(args[i + 1], 10);
    if (args[i] === '--resume') opts.resume = true;
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
 */
async function processQuestion(question) {
  // 1. Prepare sessions from this question's haystack
  const sessions = question.haystack_session_ids.map((id, i) => ({
    id,
    messages: question.haystack_sessions[i],
    date: question.haystack_dates[i],
  }));

  // 2. Ingest: extract facts from this question's haystack
  const facts = await ingest(sessions);

  // 3. Search: find relevant facts
  const retrieved = await search(question.question, facts);

  // 4. Answer: generate hypothesis
  const hypothesis = await answer(question.question, retrieved);

  // 5. Evaluate: judge correctness
  const { label, judgeResponse } = await evaluate({
    questionType: question.question_type,
    questionId: question.question_id,
    question: question.question,
    answer: question.answer,
    hypothesis,
  });

  return {
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

  // Load dataset
  console.log('\nLoading dataset...');
  const dataset = JSON.parse(readFileSync(FILES.s_cleaned.path, 'utf-8'));
  console.log(`  ${dataset.length} questions loaded`);

  let toProcess = [...dataset];

  if (opts.resume) {
    const done = loadProcessedIds();
    const before = toProcess.length;
    toProcess = toProcess.filter(q => !done.has(q.question_id));
    console.log(`  Resuming: ${before - toProcess.length} done, ${toProcess.length} remaining`);
  }

  if (opts.limit > 0) {
    toProcess = toProcess.slice(0, opts.limit);
    console.log(`  Limited to ${toProcess.length} questions`);
  }

  if (!opts.resume) {
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
