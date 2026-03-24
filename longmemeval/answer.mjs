#!/usr/bin/env node

// Stage 3: Answer — Generate answers from retrieved context
// Reads search results and generates answers using Claude Haiku.
//
// Usage: node answer.mjs [--limit N] [--resume] [--model MODEL]
//   --limit N     Process only the first N questions
//   --resume      Skip questions already answered
//   --model MODEL Override model (default: claude-haiku-4-5-20250514)

import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

// ─── Config ─────────────────────────────────────────────────────────

const SEARCH_FILE = 'output/search_results.jsonl';
const OUTPUT_FILE = 'output/hypotheses.jsonl';
const DEFAULT_MODEL = 'claude-haiku-4-5-20250514';
const API_URL = 'https://api.anthropic.com/v1/messages';
const MAX_RETRIES = 3;
const CONCURRENCY = 10;

const ANSWER_PROMPT = `You are a helpful assistant with access to a memory store of past conversations with the user. Based on the retrieved memories below, answer the user's question.

Rules:
- Answer based ONLY on the provided memories
- If the memories contain contradictory information, prefer the most recent one (check dates)
- If the memories don't contain enough information to answer, say "I don't have enough information to answer this question"
- Be concise and direct
- If the question asks about something the assistant previously said/recommended, look for assistant_info type memories

Retrieved Memories:`;

// ─── Helpers ────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { limit: 0, resume: false, model: DEFAULT_MODEL };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--limit' && args[i + 1]) opts.limit = parseInt(args[i + 1], 10);
    if (args[i] === '--resume') opts.resume = true;
    if (args[i] === '--model' && args[i + 1]) opts.model = args[i + 1];
  }
  return opts;
}

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function callClaude(messages, model, retries = MAX_RETRIES) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY not set');

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model,
          max_tokens: 1024,
          messages,
        }),
      });

      if (res.status === 429 || res.status >= 500) {
        const wait = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        console.error(`  [retry ${attempt + 1}/${retries}] HTTP ${res.status}`);
        await sleep(wait);
        continue;
      }

      if (!res.ok) {
        const body = await res.text();
        throw new Error(`API error ${res.status}: ${body}`);
      }

      const data = await res.json();
      return data.content[0].text;
    } catch (err) {
      if (attempt === retries) throw err;
      await sleep(Math.pow(2, attempt) * 1000);
    }
  }
}

function loadProcessedQuestionIds() {
  if (!existsSync(OUTPUT_FILE)) return new Set();
  const lines = readFileSync(OUTPUT_FILE, 'utf-8').split('\n').filter(Boolean);
  return new Set(lines.map(line => {
    try { return JSON.parse(line).question_id; } catch { return null; }
  }).filter(Boolean));
}

function formatContext(facts) {
  if (!facts || facts.length === 0) return '(No relevant memories found)';
  return facts
    .map((f, i) => `[${i + 1}] (${f.date || 'unknown date'}, ${f.type}) ${f.fact}`)
    .join('\n');
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs();

  if (!existsSync(SEARCH_FILE)) {
    console.error(`Search results not found: ${SEARCH_FILE}`);
    console.error('Run: node search.mjs');
    process.exit(1);
  }

  const searchResults = readFileSync(SEARCH_FILE, 'utf-8')
    .split('\n')
    .filter(Boolean)
    .map(line => JSON.parse(line));

  console.log(`Loaded ${searchResults.length} search results`);

  let toProcess = [...searchResults];

  if (opts.resume) {
    const processed = loadProcessedQuestionIds();
    const before = toProcess.length;
    toProcess = toProcess.filter(r => !processed.has(r.question_id));
    console.log(`Resuming: ${before - toProcess.length} done, ${toProcess.length} remaining`);
  }

  if (opts.limit > 0) {
    toProcess = toProcess.slice(0, opts.limit);
    console.log(`Limited to ${toProcess.length} questions`);
  }

  mkdirSync(dirname(OUTPUT_FILE), { recursive: true });

  // Clear output if starting fresh
  if (!opts.resume) {
    writeFileSync(OUTPUT_FILE, '');
  }

  console.log(`Answering ${toProcess.length} questions with ${opts.model}...`);
  let done = 0;

  for (let i = 0; i < toProcess.length; i += CONCURRENCY) {
    const batch = toProcess.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (searchResult) => {
        const context = formatContext(searchResult.retrieved_facts);
        const prompt = `${ANSWER_PROMPT}\n\n${context}\n\nQuestion: ${searchResult.question}`;

        const answer = await callClaude(
          [{ role: 'user', content: prompt }],
          opts.model,
        );

        return {
          question_id: searchResult.question_id,
          hypothesis: answer.trim(),
        };
      })
    );

    const lines = [];
    for (const r of results) {
      done++;
      if (r.status === 'fulfilled') {
        lines.push(JSON.stringify(r.value));
      } else {
        console.error(`\n  Error: ${r.reason?.message || r.reason}`);
      }
    }

    if (lines.length > 0) {
      appendFileSync(OUTPUT_FILE, lines.join('\n') + '\n');
    }

    const pct = Math.round((Math.min(i + CONCURRENCY, toProcess.length) / toProcess.length) * 100);
    process.stderr.write(`\r  [${pct}%] ${Math.min(i + CONCURRENCY, toProcess.length)}/${toProcess.length} answered`);
  }

  console.log(`\nDone. Hypotheses → ${OUTPUT_FILE}`);
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
