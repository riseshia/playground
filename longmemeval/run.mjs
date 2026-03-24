#!/usr/bin/env node

// LongMemEval Benchmark Runner
// Orchestrates the full pipeline: download → ingest → search → answer → evaluate → report
//
// Usage:
//   node run.mjs              Run full pipeline
//   node run.mjs download     Download dataset only
//   node run.mjs --resume     Resume from last checkpoint
//   node run.mjs --limit N    Limit to N questions (for testing)
//
// Environment:
//   OPENAI_API_KEY      Required for evaluate
// Prerequisites:
//   claude CLI           Required for ingest/search/answer

import { execSync } from 'child_process';
import { existsSync, mkdirSync } from 'fs';

// ─── Config ─────────────────────────────────────────────────────────

const BASE_URL = 'https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned/resolve/main';
const FILES = {
  's_cleaned': { url: `${BASE_URL}/longmemeval_s_cleaned.json`, path: 'data/longmemeval_s_cleaned.json', size: '277MB' },
  'oracle': { url: `${BASE_URL}/longmemeval_oracle.json`, path: 'data/longmemeval_oracle.json', size: '15MB' },
};

const STAGES = [
  { name: 'ingest', script: 'ingest.mjs', output: 'output/facts.jsonl', desc: 'Extract facts from sessions' },
  { name: 'search', script: 'search.mjs', output: 'output/search_results.jsonl', desc: 'Search facts for each question' },
  { name: 'answer', script: 'answer.mjs', output: 'output/hypotheses.jsonl', desc: 'Generate answers' },
  { name: 'evaluate', script: 'evaluate.mjs', output: 'output/eval_results.jsonl', desc: 'Judge correctness' },
  { name: 'report', script: 'report.mjs', output: null, desc: 'Print results' },
];

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
      console.log(`  ✓ ${name} already downloaded (${file.path})`);
      continue;
    }
    console.log(`  ↓ Downloading ${name} (${file.size})...`);
    try {
      execSync(`curl -sL -o "${file.path}" "${file.url}"`, { stdio: 'inherit' });
      console.log(`  ✓ ${name} → ${file.path}`);
    } catch (err) {
      console.error(`  ✗ Failed to download ${name}: ${err.message}`);
      process.exit(1);
    }
  }
}

function runStage(stage, opts) {
  const args = [];
  if (opts.limit > 0) args.push('--limit', opts.limit);
  if (opts.resume) args.push('--resume');

  const cmd = `node ${stage.script} ${args.join(' ')}`;
  console.log(`\n${'─'.repeat(60)}`);
  console.log(`Stage: ${stage.name} — ${stage.desc}`);
  console.log(`${'─'.repeat(60)}`);

  try {
    execSync(cmd, { stdio: 'inherit', cwd: process.cwd() });
  } catch (err) {
    console.error(`\n✗ Stage "${stage.name}" failed with exit code ${err.status}`);
    process.exit(1);
  }
}

// ─── Main ───────────────────────────────────────────────────────────

function main() {
  const opts = parseArgs();

  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  LongMemEval Benchmark — ASMR-lite (JSONL + grep)  ║');
  console.log('╚══════════════════════════════════════════════════════╝');
  console.log();

  // Check environment
  if (opts.command === 'run') {
    if (!process.env.OPENAI_API_KEY) {
      console.error('Error: OPENAI_API_KEY not set (required for evaluate stage)');
      process.exit(1);
    }
  }

  // Download
  if (opts.command === 'download' || opts.command === 'run') {
    console.log('Downloading dataset...');
    download();
    if (opts.command === 'download') {
      console.log('\nDone. Run `node run.mjs` to start the benchmark.');
      return;
    }
  }

  // Create output directory
  mkdirSync('output', { recursive: true });

  // Run pipeline
  const startTime = Date.now();

  for (const stage of STAGES) {
    // Skip stages with existing output (unless no resume flag)
    if (stage.output && existsSync(stage.output) && !opts.resume && opts.limit === 0) {
      console.log(`\n  ⏭ Skipping ${stage.name} (${stage.output} exists, use --resume to update)`);
      continue;
    }
    runStage(stage, opts);
  }

  const elapsed = ((Date.now() - startTime) / 1000 / 60).toFixed(1);
  console.log(`\n✓ Pipeline complete in ${elapsed} minutes`);
}

main();
