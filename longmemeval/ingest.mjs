#!/usr/bin/env node

// Stage 1: Ingest — Extract structured facts from conversation sessions
// Reads longmemeval_s_cleaned.json, sends each session to Claude Haiku,
// and writes extracted facts to output/facts.jsonl
//
// Usage: node ingest.mjs [--limit N] [--resume]
//   --limit N   Process only the first N questions (for testing)
//   --resume    Skip sessions already processed (based on facts.jsonl)

import { readFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

// ─── Config ─────────────────────────────────────────────────────────

const DATA_FILE = 'data/longmemeval_s_cleaned.json';
const OUTPUT_FILE = 'output/facts.jsonl';
const MODEL = 'claude-haiku-4-5-20250514';
const API_URL = 'https://api.anthropic.com/v1/messages';
const MAX_RETRIES = 3;
const CONCURRENCY = 5;

const EXTRACT_PROMPT = `You are a memory extraction agent. Given a conversation between a user and an assistant, extract all memorable facts as structured JSON.

For each fact, determine:
- type: one of "personal_info", "preference", "event", "temporal", "update", "assistant_info"
- fact: a concise statement of the fact (one sentence)
- keywords: 3-8 lowercase keywords for search

Types:
- personal_info: name, location, job, education, family, pets, etc.
- preference: likes, dislikes, favorites, habits
- event: things that happened, plans, appointments
- temporal: time-specific info (dates, durations, sequences)
- update: corrections or changes to previously stated info (include what changed)
- assistant_info: recommendations, advice, or info the assistant provided that the user acknowledged

Rules:
- Extract ONLY facts explicitly stated or strongly implied in the conversation
- Each fact should be self-contained and understandable without context
- For updates, note what the previous value was if mentioned
- Skip generic chitchat with no memorable content
- If the conversation has no memorable facts, return an empty array

Respond with a JSON array only, no markdown:
[{"type": "...", "fact": "...", "keywords": ["...", "..."]}]`;

// ─── Helpers ────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { limit: 0, resume: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--limit' && args[i + 1]) opts.limit = parseInt(args[i + 1], 10);
    if (args[i] === '--resume') opts.resume = true;
  }
  return opts;
}

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function callClaude(messages, retries = MAX_RETRIES) {
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
          model: MODEL,
          max_tokens: 4096,
          messages,
        }),
      });

      if (res.status === 429 || res.status >= 500) {
        const wait = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        console.error(`  [retry ${attempt + 1}/${retries}] HTTP ${res.status}, waiting ${Math.round(wait)}ms`);
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
      const wait = Math.pow(2, attempt) * 1000;
      console.error(`  [retry ${attempt + 1}/${retries}] ${err.message}, waiting ${wait}ms`);
      await sleep(wait);
    }
  }
}

function formatSession(messages) {
  return messages
    .map(m => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`)
    .join('\n\n');
}

function loadProcessedSessionIds() {
  if (!existsSync(OUTPUT_FILE)) return new Set();
  const lines = readFileSync(OUTPUT_FILE, 'utf-8').split('\n').filter(Boolean);
  const ids = new Set();
  for (const line of lines) {
    try {
      const fact = JSON.parse(line);
      ids.add(fact.session_id);
    } catch { /* skip */ }
  }
  return ids;
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs();

  if (!existsSync(DATA_FILE)) {
    console.error(`Dataset not found: ${DATA_FILE}`);
    console.error('Run: node run.mjs download');
    process.exit(1);
  }

  mkdirSync(dirname(OUTPUT_FILE), { recursive: true });

  console.log('Loading dataset...');
  const dataset = JSON.parse(readFileSync(DATA_FILE, 'utf-8'));

  // Collect unique sessions across all questions
  // Each question has haystack_sessions (array of session arrays) with corresponding IDs and dates
  const sessionMap = new Map(); // session_id -> { messages, date }
  for (const q of dataset) {
    for (let i = 0; i < q.haystack_session_ids.length; i++) {
      const sid = q.haystack_session_ids[i];
      if (!sessionMap.has(sid)) {
        sessionMap.set(sid, {
          messages: q.haystack_sessions[i],
          date: q.haystack_dates[i],
        });
      }
    }
  }

  let sessions = Array.from(sessionMap.entries()).map(([id, data]) => ({
    id,
    messages: data.messages,
    date: data.date,
  }));

  console.log(`Found ${sessions.length} unique sessions across ${dataset.length} questions`);

  // Resume support
  if (opts.resume) {
    const processed = loadProcessedSessionIds();
    const before = sessions.length;
    sessions = sessions.filter(s => !processed.has(s.id));
    console.log(`Resuming: ${before - sessions.length} already processed, ${sessions.length} remaining`);
  }

  if (opts.limit > 0) {
    sessions = sessions.slice(0, opts.limit);
    console.log(`Limited to ${sessions.length} sessions`);
  }

  console.log(`Processing ${sessions.length} sessions...`);
  let factCount = 0;
  let processed = 0;

  // Process in batches for concurrency
  for (let i = 0; i < sessions.length; i += CONCURRENCY) {
    const batch = sessions.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (session) => {
        const text = formatSession(session.messages);

        // Skip very short sessions (likely no useful facts)
        if (text.length < 50) return [];

        const response = await callClaude([
          { role: 'user', content: `${EXTRACT_PROMPT}\n\n--- CONVERSATION (${session.date}) ---\n${text}` },
        ]);

        // Parse JSON from response
        let facts;
        try {
          // Handle potential markdown wrapping
          const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
          facts = JSON.parse(cleaned);
        } catch {
          console.error(`  Failed to parse response for session ${session.id}`);
          return [];
        }

        if (!Array.isArray(facts)) return [];

        // Write facts to JSONL
        const lines = [];
        for (const f of facts) {
          const fact = {
            id: `f_${session.id}_${lines.length}`,
            session_id: session.id,
            date: session.date,
            type: f.type || 'personal_info',
            fact: f.fact,
            keywords: (f.keywords || []).map(k => k.toLowerCase()),
          };
          if (f.supersedes) fact.supersedes = f.supersedes;
          lines.push(JSON.stringify(fact));
        }

        if (lines.length > 0) {
          appendFileSync(OUTPUT_FILE, lines.join('\n') + '\n');
        }

        return facts;
      })
    );

    for (const r of results) {
      processed++;
      if (r.status === 'fulfilled') {
        factCount += r.value.length;
      } else {
        console.error(`  Error: ${r.reason?.message || r.reason}`);
      }
    }

    const pct = Math.round((Math.min(i + CONCURRENCY, sessions.length) / sessions.length) * 100);
    process.stderr.write(`\r  [${pct}%] ${Math.min(i + CONCURRENCY, sessions.length)}/${sessions.length} sessions, ${factCount} facts extracted`);
  }

  console.log(`\nDone. Extracted ${factCount} facts from ${processed} sessions → ${OUTPUT_FILE}`);
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
