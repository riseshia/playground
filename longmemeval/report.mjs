#!/usr/bin/env node

// Stage 5: Report — Aggregate evaluation results by category.
// Reads output/results.jsonl and prints accuracy breakdown.

import { readFileSync, existsSync } from 'fs';

const RESULTS_FILE = 'output/results.jsonl';

function main() {
  if (!existsSync(RESULTS_FILE)) {
    console.error(`Results not found: ${RESULTS_FILE}`);
    console.error('Run: node run.mjs');
    process.exit(1);
  }

  const results = readFileSync(RESULTS_FILE, 'utf-8')
    .split('\n')
    .filter(Boolean)
    .map(line => JSON.parse(line));

  if (results.length === 0) {
    console.log('No results to report.');
    return;
  }

  const byType = {};
  let totalCorrect = 0;
  let totalCount = 0;

  for (const r of results) {
    const type = r.question_type;
    if (!type) continue; // skip error entries
    if (!byType[type]) byType[type] = { correct: 0, total: 0 };
    byType[type].total++;
    totalCount++;
    if (r.label) {
      byType[type].correct++;
      totalCorrect++;
    }
  }

  const LINE = '═'.repeat(55);
  console.log();
  console.log(LINE);
  console.log('  LongMemEval_s Results (ASMR-lite / JSONL + grep)');
  console.log(LINE);
  console.log();
  console.log(`  Overall: ${totalCorrect}/${totalCount} (${(totalCorrect / totalCount * 100).toFixed(1)}%)`);
  console.log();
  console.log('  By Category:');

  const typeOrder = [
    'single-session-user',
    'single-session-assistant',
    'single-session-preference',
    'multi-session',
    'temporal-reasoning',
    'knowledge-update',
  ];

  const types = typeOrder.filter(t => byType[t]);
  for (const t of Object.keys(byType)) {
    if (!types.includes(t)) types.push(t);
  }

  for (const type of types) {
    const { correct, total } = byType[type];
    const pct = (correct / total * 100).toFixed(1);
    const bar = '█'.repeat(Math.round(correct / total * 20)) + '░'.repeat(20 - Math.round(correct / total * 20));
    console.log(`    ${type.padEnd(30)} ${bar} ${pct.padStart(5)}% (${correct}/${total})`);
  }

  console.log();
  console.log(LINE);
  console.log();
  console.log('  Reference scores (LongMemEval_s):');
  console.log('    Supermemory ASMR:              81.6%');
  console.log('    Zep:                           71.2%');
  console.log('    Mem0:                          23.0%');
  console.log('    GPT-4o (128k context):         ~50%');
  console.log();
}

main();
