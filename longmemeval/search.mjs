// Stage 2: Search — Find relevant facts for a question.
// Uses 3 specialized search agents (Direct Seeker, Inference Engine, Temporal Reasoner)
// run in parallel. Each agent reads the facts file directly via tool use (grep/read).

import { callClaude, parseJSON } from './lib.mjs';

// ─── Agent Prompts ──────────────────────────────────────────────────

const DIRECT_SEEKER_PROMPT = `You are a Direct Seeker agent. Your task is to find facts that directly match the question through exact or near-exact keyword/entity matching.

You have access to a JSONL file where each line is a JSON object with fields: id, session_id, date, type, fact, keywords.

Strategy:
- Use grep/read tools to search the facts file for entities, names, or specific terms from the question
- Try multiple search terms including synonyms
- Prioritize recent facts when multiple matches exist

After searching, respond with a JSON array of fact IDs that are relevant, ordered by relevance (most relevant first).
Respond with JSON only, no markdown:
["f_0", "f_3", ...]

If no facts are relevant, respond with: []`;

const INFERENCE_ENGINE_PROMPT = `You are an Inference Engine agent. Your task is to find facts that are indirectly relevant through implication, context, or causal relationships.

You have access to a JSONL file where each line is a JSON object with fields: id, session_id, date, type, fact, keywords.

Strategy:
- Use grep/read tools to search the facts file broadly
- Find facts related through implication or cause-and-effect (e.g., "service" → look for problems, issues, complaints)
- Search for categories of information the answer likely belongs to
- Think about what the answer might look like and search for those terms too

After searching, respond with a JSON array of fact IDs that are relevant, ordered by relevance (most relevant first).
Respond with JSON only, no markdown:
["f_0", "f_3", ...]

If no facts are relevant, respond with: []`;

const TEMPORAL_REASONER_PROMPT = `You are a Temporal Reasoner agent. Your task is to find facts relevant through temporal/chronological reasoning.

You have access to a JSONL file where each line is a JSON object with fields: id, session_id, date, type, fact, keywords.

Strategy:
- Use grep/read tools to search the facts file
- If the question asks about "after X" or "before Y", first find event X/Y, then search for events in the correct time window
- Track state changes (e.g., something broke then got fixed)
- Look for facts with type "temporal" or "update" that may be relevant
- Calculate durations or sequences when needed

After searching, respond with a JSON array of fact IDs that are relevant, ordered by relevance (most relevant first).
Respond with JSON only, no markdown:
["f_0", "f_3", ...]

If no facts are relevant, respond with: []`;

// ─── Helpers ────────────────────────────────────────────────────────

async function runAgent(prompt, question, factsFile) {
  const fullPrompt = `${prompt}\n\nFacts file: ${factsFile}\n\nQuestion: ${question}`;
  try {
    const response = await callClaude(fullPrompt);
    const ids = parseJSON(response);
    if (!Array.isArray(ids)) return [];
    return ids.filter(id => typeof id === 'string');
  } catch {
    return [];
  }
}

// ─── Main Search ────────────────────────────────────────────────────

/**
 * Search facts for a question using 3 parallel search agents.
 * Each agent reads the facts file directly using tools.
 * @param {string} question
 * @param {Array} facts
 * @param {string} factsFile - path to facts.jsonl
 * @param {number} topK
 * @returns {Promise<Array>}
 */
export async function search(question, facts, factsFile, topK = 15) {
  if (facts.length === 0) return [];

  const factMap = new Map(facts.map(f => [f.id, f]));

  // Run 3 agents in parallel
  const [directIds, inferenceIds, temporalIds] = await Promise.all([
    runAgent(DIRECT_SEEKER_PROMPT, question, factsFile),
    runAgent(INFERENCE_ENGINE_PROMPT, question, factsFile),
    runAgent(TEMPORAL_REASONER_PROMPT, question, factsFile),
  ]);

  // Merge with weighted scoring: earlier position = higher score
  const scoreMap = new Map();

  function addScores(ids, weight) {
    for (let i = 0; i < ids.length; i++) {
      const id = ids[i];
      if (!factMap.has(id)) continue;
      const positionScore = Math.max(1, 10 - i);
      const prev = scoreMap.get(id) || 0;
      scoreMap.set(id, prev + positionScore * weight);
    }
  }

  addScores(directIds, 3);
  addScores(inferenceIds, 2);
  addScores(temporalIds, 2);

  // Sort by merged score, take top-K
  const results = Array.from(scoreMap.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, topK)
    .map(([id, score]) => ({ ...factMap.get(id), _score: score }));

  return results;
}
