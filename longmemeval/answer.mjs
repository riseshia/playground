// Stage 3: Answer — Generate an answer from retrieved facts.

import { callClaude } from './lib.mjs';

const ANSWER_PROMPT = `You are a helpful assistant with access to a memory store of past conversations with the user. Based on the retrieved memories below, answer the user's question.

Rules:
- Answer based ONLY on the provided memories
- If the memories contain contradictory information, prefer the most recent one (check dates)
- If the memories don't contain enough information to answer, say "I don't have enough information to answer this question"
- Be concise and direct
- If the question asks about something the assistant previously said/recommended, look for assistant_info type memories`;

/**
 * Generate an answer from retrieved facts.
 * @param {string} question
 * @param {Array} facts
 * @returns {Promise<string>}
 */
export async function answer(question, facts) {
  let context;
  if (!facts || facts.length === 0) {
    context = '(No relevant memories found)';
  } else {
    context = facts
      .map((f, i) => `[${i + 1}] (${f.date || 'unknown date'}, ${f.type}) ${f.fact}`)
      .join('\n');
  }

  const prompt = `${ANSWER_PROMPT}\n\nRetrieved Memories:\n${context}\n\nQuestion: ${question}`;
  const response = await callClaude(prompt);
  return response.trim();
}
