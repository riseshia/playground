#!/usr/bin/env node

// Stage 4: Evaluate — Judge answer correctness using GPT-4o
// Ports the LongMemEval evaluate_qa.py logic to JavaScript.
// Each hypothesis is compared against the ground truth by GPT-4o.
//
// Usage: node evaluate.mjs [--limit N] [--resume] [--model MODEL]
//   --limit N     Process only the first N questions
//   --resume      Skip questions already evaluated
//   --model MODEL Override judge model (default: gpt-4o)

import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

// ─── Config ─────────────────────────────────────────────────────────

const ORACLE_FILE = 'data/longmemeval_oracle.json';
const HYPOTHESES_FILE = 'output/hypotheses.jsonl';
const OUTPUT_FILE = 'output/eval_results.jsonl';
const DEFAULT_MODEL = 'gpt-4o';
const API_URL = 'https://api.openai.com/v1/chat/completions';
const MAX_RETRIES = 3;
const CONCURRENCY = 10;

// ─── Prompt Templates (ported from evaluate_qa.py) ──────────────────

const PROMPTS = {
  standard: `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response is equivalent to the correct answer or contains all the intermediate steps to get the correct answer, you should also answer yes. If the response only contains a subset of the information required by the answer, answer no.

Question: {question}

Correct Answer: {answer}

Model Response: {hypothesis}

Is the model response correct? Answer yes or no only.`,

  'temporal-reasoning': `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response is equivalent to the correct answer or contains all the intermediate steps to get the correct answer, you should also answer yes. If the response only contains a subset of the information required by the answer, answer no. In addition, do not penalize off-by-one errors for the number of days. If the question asks for the number of days/weeks/months, etc., and the model makes off-by-one errors (e.g., predicting 19 days when the answer is 18), the model's response is still correct.

Question: {question}

Correct Answer: {answer}

Model Response: {hypothesis}

Is the model response correct? Answer yes or no only.`,

  'knowledge-update': `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response contains some previous information along with an updated answer, the response should be considered as correct as long as the updated answer is the required answer.

Question: {question}

Correct Answer: {answer}

Model Response: {hypothesis}

Is the model response correct? Answer yes or no only.`,

  'single-session-preference': `I will give you a question, a rubric for desired personalized response, and a response from a model. Please answer yes if the response satisfies the desired response. Otherwise, answer no. The model does not need to reflect all the points in the rubric. The response is correct as long as it recalls and utilizes the user's personal information correctly.

Question: {question}

Rubric: {answer}

Model Response: {hypothesis}

Is the model response correct? Answer yes or no only.`,

  abstention: `I will give you an unanswerable question, an explanation, and a response from a model. Please answer yes if the model correctly identifies the question as unanswerable. The model could say that the information is incomplete, or some other information is given but the asked information is not.

Question: {question}

Explanation: {answer}

Model Response: {hypothesis}

Does the model correctly identify the question as unanswerable? Answer yes or no only.`,
};

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

async function callOpenAI(prompt, model, retries = MAX_RETRIES) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error('OPENAI_API_KEY not set');

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0,
          max_tokens: 10,
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
      return data.choices[0].message.content.trim();
    } catch (err) {
      if (attempt === retries) throw err;
      await sleep(Math.pow(2, attempt) * 1000);
    }
  }
}

function getPrompt(questionType, questionId, question, answer, hypothesis) {
  // Check for abstention questions
  const isAbstention = questionId.includes('_abs');

  let template;
  if (isAbstention) {
    template = PROMPTS.abstention;
  } else if (PROMPTS[questionType]) {
    template = PROMPTS[questionType];
  } else {
    template = PROMPTS.standard;
  }

  return template
    .replace('{question}', question)
    .replace('{answer}', answer)
    .replace('{hypothesis}', hypothesis);
}

function loadProcessedQuestionIds() {
  if (!existsSync(OUTPUT_FILE)) return new Set();
  const lines = readFileSync(OUTPUT_FILE, 'utf-8').split('\n').filter(Boolean);
  return new Set(lines.map(line => {
    try { return JSON.parse(line).question_id; } catch { return null; }
  }).filter(Boolean));
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs();

  if (!existsSync(HYPOTHESES_FILE)) {
    console.error(`Hypotheses not found: ${HYPOTHESES_FILE}`);
    console.error('Run: node answer.mjs');
    process.exit(1);
  }

  if (!existsSync(ORACLE_FILE)) {
    console.error(`Oracle data not found: ${ORACLE_FILE}`);
    console.error('Run: node run.mjs download');
    process.exit(1);
  }

  // Load reference data
  const oracle = JSON.parse(readFileSync(ORACLE_FILE, 'utf-8'));
  const oracleMap = new Map(oracle.map(q => [q.question_id, q]));

  // Load hypotheses
  const hypotheses = readFileSync(HYPOTHESES_FILE, 'utf-8')
    .split('\n')
    .filter(Boolean)
    .map(line => JSON.parse(line));

  console.log(`Loaded ${hypotheses.length} hypotheses, ${oracle.length} reference questions`);

  let toProcess = [...hypotheses];

  if (opts.resume) {
    const processed = loadProcessedQuestionIds();
    const before = toProcess.length;
    toProcess = toProcess.filter(h => !processed.has(h.question_id));
    console.log(`Resuming: ${before - toProcess.length} done, ${toProcess.length} remaining`);
  }

  if (opts.limit > 0) {
    toProcess = toProcess.slice(0, opts.limit);
    console.log(`Limited to ${toProcess.length} questions`);
  }

  mkdirSync(dirname(OUTPUT_FILE), { recursive: true });

  if (!opts.resume) {
    writeFileSync(OUTPUT_FILE, '');
  }

  console.log(`Evaluating ${toProcess.length} answers with ${opts.model}...`);
  let correct = 0;
  let total = 0;

  for (let i = 0; i < toProcess.length; i += CONCURRENCY) {
    const batch = toProcess.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (hyp) => {
        const ref = oracleMap.get(hyp.question_id);
        if (!ref) {
          console.error(`\n  Warning: ${hyp.question_id} not in oracle, skipping`);
          return null;
        }

        const prompt = getPrompt(
          ref.question_type,
          ref.question_id,
          ref.question,
          ref.answer,
          hyp.hypothesis,
        );

        const response = await callOpenAI(prompt, opts.model);
        const label = response.toLowerCase().includes('yes');

        return {
          question_id: hyp.question_id,
          question_type: ref.question_type,
          label,
          judge_response: response,
        };
      })
    );

    const lines = [];
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value) {
        total++;
        if (r.value.label) correct++;
        lines.push(JSON.stringify(r.value));
      } else if (r.status === 'rejected') {
        console.error(`\n  Error: ${r.reason?.message || r.reason}`);
      }
    }

    if (lines.length > 0) {
      appendFileSync(OUTPUT_FILE, lines.join('\n') + '\n');
    }

    const pct = Math.round((Math.min(i + CONCURRENCY, toProcess.length) / toProcess.length) * 100);
    const acc = total > 0 ? (correct / total * 100).toFixed(1) : '0.0';
    process.stderr.write(`\r  [${pct}%] ${Math.min(i + CONCURRENCY, toProcess.length)}/${toProcess.length} evaluated, running accuracy: ${acc}%`);
  }

  console.log(`\nDone. Results → ${OUTPUT_FILE}`);
  console.log(`Overall: ${correct}/${total} (${(correct / total * 100).toFixed(1)}%)`);
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
