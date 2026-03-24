#!/usr/bin/env node

// Stage 2: Search — Find relevant facts for each question
// Reads questions from dataset + facts from facts.jsonl,
// uses keyword extraction + grep-style matching to find relevant context.
//
// Usage: node search.mjs [--limit N] [--resume] [--top-k K]
//   --limit N   Process only the first N questions
//   --resume    Skip questions already processed
//   --top-k K   Number of facts to retrieve per question (default: 15)

import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { execFile } from 'child_process';

// ─── Config ─────────────────────────────────────────────────────────

const ORACLE_FILE = 'data/longmemeval_oracle.json';
const FACTS_FILE = 'output/facts.jsonl';
const OUTPUT_FILE = 'output/search_results.jsonl';
const MODEL = 'claude-haiku-4-5';
const MAX_RETRIES = 3;
const CONCURRENCY = 10;
const DEFAULT_TOP_K = 15;

const KEYWORD_PROMPT = `Given a question from a user about their past conversations, extract search keywords and metadata to find relevant facts in a memory store.

Respond with JSON only (no markdown):
{
  "keywords": ["keyword1", "keyword2", ...],
  "fact_types": ["personal_info", "preference", ...],
  "time_hint": "YYYY/MM or null"
}

Rules:
- keywords: 5-15 lowercase search terms. Include synonyms, related terms.
- fact_types: which fact types are most likely relevant. Options: personal_info, preference, event, temporal, update, assistant_info
- time_hint: if the question implies a specific time period, provide it. Otherwise null.`;

// ─── Helpers ────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { limit: 0, resume: false, topK: DEFAULT_TOP_K };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--limit' && args[i + 1]) opts.limit = parseInt(args[i + 1], 10);
    if (args[i] === '--resume') opts.resume = true;
    if (args[i] === '--top-k' && args[i + 1]) opts.topK = parseInt(args[i + 1], 10);
  }
  return opts;
}

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

function callClaudeOnce(prompt) {
  return new Promise((resolve, reject) => {
    execFile('claude', ['-p', prompt, '--model', MODEL, '--output-format', 'text', '--system-prompt', ''], {
      maxBuffer: 10 * 1024 * 1024,
    }, (err, stdout, stderr) => {
      if (err) return reject(new Error(stderr || err.message));
      resolve(stdout.trim());
    });
  });
}

async function callClaude(messages, retries = MAX_RETRIES) {
  const prompt = messages.map(m => m.content).join('\n\n');
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await callClaudeOnce(prompt);
    } catch (err) {
      if (attempt === retries) throw err;
      await sleep(Math.pow(2, attempt) * 1000);
    }
  }
}

function loadFacts() {
  if (!existsSync(FACTS_FILE)) {
    console.error(`Facts file not found: ${FACTS_FILE}`);
    console.error('Run: node ingest.mjs');
    process.exit(1);
  }
  const lines = readFileSync(FACTS_FILE, 'utf-8').split('\n').filter(Boolean);
  return lines.map(line => JSON.parse(line));
}

function loadProcessedQuestionIds() {
  if (!existsSync(OUTPUT_FILE)) return new Set();
  const lines = readFileSync(OUTPUT_FILE, 'utf-8').split('\n').filter(Boolean);
  return new Set(lines.map(line => {
    try { return JSON.parse(line).question_id; } catch { return null; }
  }).filter(Boolean));
}

// Score a fact against search criteria
function scoreFact(fact, keywords, factTypes, timeHint) {
  let score = 0;

  // Keyword matching in fact text and keywords
  const factText = (fact.fact + ' ' + fact.keywords.join(' ')).toLowerCase();
  for (const kw of keywords) {
    if (factText.includes(kw.toLowerCase())) {
      score += 2;
    }
  }

  // Partial keyword matching (substring)
  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    for (const fkw of fact.keywords) {
      if (fkw.includes(kwLower) || kwLower.includes(fkw)) {
        score += 1;
      }
    }
  }

  // Fact type bonus
  if (factTypes.includes(fact.type)) {
    score += 3;
  }

  // Time proximity bonus
  if (timeHint && fact.date) {
    const factMonth = fact.date.substring(0, 7); // "YYYY/MM"
    if (factMonth === timeHint) {
      score += 5;
    } else if (factMonth.substring(0, 4) === timeHint.substring(0, 4)) {
      score += 1; // Same year
    }
  }

  // Penalize update type slightly unless specifically looking for updates
  // (updates are important but should be ranked with their superseding info)
  if (fact.type === 'update' && !factTypes.includes('update')) {
    score += 1; // Small bonus — updates often have latest info
  }

  return score;
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs();

  console.log('Loading facts...');
  const facts = loadFacts();
  console.log(`Loaded ${facts.length} facts`);

  console.log('Loading questions...');
  const questions = JSON.parse(readFileSync(ORACLE_FILE, 'utf-8'));
  console.log(`Loaded ${questions.length} questions`);

  let toProcess = [...questions];

  if (opts.resume) {
    const processed = loadProcessedQuestionIds();
    const before = toProcess.length;
    toProcess = toProcess.filter(q => !processed.has(q.question_id));
    console.log(`Resuming: ${before - toProcess.length} done, ${toProcess.length} remaining`);
  }

  if (opts.limit > 0) {
    toProcess = toProcess.slice(0, opts.limit);
    console.log(`Limited to ${toProcess.length} questions`);
  }

  mkdirSync(dirname(OUTPUT_FILE), { recursive: true });

  console.log(`Searching ${toProcess.length} questions (top-${opts.topK})...`);
  let done = 0;

  for (let i = 0; i < toProcess.length; i += CONCURRENCY) {
    const batch = toProcess.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (question) => {
        // Extract keywords via Claude
        const response = await callClaude([
          { role: 'user', content: `${KEYWORD_PROMPT}\n\nQuestion: ${question.question}` },
        ]);

        let parsed;
        try {
          const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
          parsed = JSON.parse(cleaned);
        } catch {
          // Fallback: extract words from question
          parsed = {
            keywords: question.question.toLowerCase().split(/\W+/).filter(w => w.length > 2),
            fact_types: ['personal_info', 'preference', 'event'],
            time_hint: null,
          };
        }

        const { keywords = [], fact_types: factTypes = [], time_hint: timeHint = null } = parsed;

        // Score all facts
        const scored = facts.map(fact => ({
          ...fact,
          _score: scoreFact(fact, keywords, factTypes, timeHint),
        }));

        // Sort by score descending, take top-K
        scored.sort((a, b) => b._score - a._score);
        const topFacts = scored.slice(0, opts.topK).filter(f => f._score > 0);

        const result = {
          question_id: question.question_id,
          question: question.question,
          question_type: question.question_type,
          search_keywords: keywords,
          search_types: factTypes,
          search_time_hint: timeHint,
          retrieved_facts: topFacts.map(f => ({
            id: f.id,
            fact: f.fact,
            type: f.type,
            date: f.date,
            score: f._score,
          })),
          retrieved_count: topFacts.length,
        };

        return result;
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
      if (i === 0 && !opts.resume) {
        writeFileSync(OUTPUT_FILE, lines.join('\n') + '\n');
      } else {
        appendFileSync(OUTPUT_FILE, lines.join('\n') + '\n');
      }
    }

    const pct = Math.round((Math.min(i + CONCURRENCY, toProcess.length) / toProcess.length) * 100);
    process.stderr.write(`\r  [${pct}%] ${Math.min(i + CONCURRENCY, toProcess.length)}/${toProcess.length} questions searched`);
  }

  console.log(`\nDone. Search results → ${OUTPUT_FILE}`);
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
