// Shared utilities for the LongMemEval pipeline.
// Uses claude CLI for Anthropic calls and OpenRouter for evaluation.

import { execFile } from 'child_process';

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const MAX_RETRIES = 3;

// ─── Helpers ────────────────────────────────────────────────────────

export async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

/**
 * Call Claude via the CLI (uses local subscription).
 */
export async function callClaude(prompt, { model = 'claude-haiku-4-5-20250514', retries = MAX_RETRIES } = {}) {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await new Promise((resolve, reject) => {
        execFile('claude', ['-p', prompt, '--model', model, '--output-format', 'text', '--system-prompt', ''], {
          maxBuffer: 10 * 1024 * 1024,
        }, (err, stdout, stderr) => {
          if (err) return reject(new Error(stderr || err.message));
          resolve(stdout.trim());
        });
      });
    } catch (err) {
      if (attempt === retries) throw err;
      const wait = Math.pow(2, attempt) * 1000;
      process.stderr.write(`  [retry ${attempt + 1}/${retries}] ${err.message}\n`);
      await sleep(wait);
    }
  }
}

/**
 * Call OpenRouter API (for evaluation with GPT-4o etc).
 */
export async function callOpenRouter(prompt, { model = 'openai/gpt-4o', maxTokens = 10, retries = MAX_RETRIES } = {}) {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) throw new Error('OPENROUTER_API_KEY not set');

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(OPENROUTER_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0,
          max_tokens: maxTokens,
        }),
      });

      if (res.status === 429 || res.status >= 500) {
        const wait = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        if (attempt < retries) {
          process.stderr.write(`  [retry ${attempt + 1}] HTTP ${res.status}\n`);
          await sleep(wait);
          continue;
        }
      }

      if (!res.ok) {
        const body = await res.text();
        throw new Error(`OpenRouter API ${res.status}: ${body.slice(0, 200)}`);
      }

      const data = await res.json();
      return data.choices[0].message.content.trim();
    } catch (err) {
      if (attempt === retries) throw err;
      await sleep(Math.pow(2, attempt) * 1000);
    }
  }
}

export function parseJSON(text) {
  const cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  return JSON.parse(cleaned);
}

export function formatSession(messages, date) {
  const header = date ? `[Session — ${date}]` : '[Session]';
  const body = messages
    .map(m => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`)
    .join('\n\n');
  return `${header}\n${body}`;
}
