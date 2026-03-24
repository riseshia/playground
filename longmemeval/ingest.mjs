// Stage 1: Ingest — Extract structured facts from conversation sessions.
// Given a list of sessions (one question's haystack), extract memorable facts.

import { callClaude, parseJSON, formatSession } from './lib.mjs';

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

const CONCURRENCY = 5;

/**
 * Extract facts from a list of sessions.
 * @param {Array<{id: string, messages: Array, date: string}>} sessions
 * @returns {Promise<Array<{id: string, session_id: string, date: string, type: string, fact: string, keywords: string[]}>>}
 */
export async function ingest(sessions) {
  const allFacts = [];
  let factCounter = 0;

  for (let i = 0; i < sessions.length; i += CONCURRENCY) {
    const batch = sessions.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (session) => {
        const text = formatSession(session.messages, session.date);
        if (text.length < 100) return [];

        const response = await callClaude(
          `${EXTRACT_PROMPT}\n\n--- CONVERSATION (${session.date}) ---\n${text}`
        );

        let extracted;
        try {
          extracted = parseJSON(response);
        } catch {
          return [];
        }

        if (!Array.isArray(extracted)) return [];

        return extracted.map(f => ({
          id: `f_${factCounter++}`,
          session_id: session.id,
          date: session.date,
          type: f.type || 'personal_info',
          fact: f.fact,
          keywords: (f.keywords || []).map(k => k.toLowerCase()),
        }));
      })
    );

    for (const r of results) {
      if (r.status === 'fulfilled') allFacts.push(...r.value);
    }
  }

  return allFacts;
}
