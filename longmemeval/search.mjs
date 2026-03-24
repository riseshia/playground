// Stage 2: Search — Find relevant facts for a question.
// Uses LLM keyword extraction + grep-style matching + scoring.

import { callClaude, parseJSON } from './lib.mjs';

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

function scoreFact(fact, keywords, factTypes, timeHint) {
  let score = 0;
  const factText = (fact.fact + ' ' + fact.keywords.join(' ')).toLowerCase();

  for (const kw of keywords) {
    if (factText.includes(kw.toLowerCase())) score += 2;
  }

  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    for (const fkw of fact.keywords) {
      if ((fkw.includes(kwLower) || kwLower.includes(fkw)) && fkw !== kwLower) {
        score += 1;
      }
    }
  }

  if (factTypes.includes(fact.type)) score += 3;

  if (timeHint && fact.date) {
    const factMonth = fact.date.substring(0, 7);
    if (factMonth === timeHint) score += 5;
    else if (factMonth.substring(0, 4) === timeHint.substring(0, 4)) score += 1;
  }

  return score;
}

/**
 * Search facts for a question. Returns top-K relevant facts.
 * @param {string} question
 * @param {Array} facts
 * @param {number} topK
 * @returns {Promise<Array>}
 */
export async function search(question, facts, topK = 15) {
  let keywords, factTypes, timeHint;
  try {
    const response = await callClaude(`${KEYWORD_PROMPT}\n\nQuestion: ${question}`);
    const parsed = parseJSON(response);
    keywords = parsed.keywords || [];
    factTypes = parsed.fact_types || [];
    timeHint = parsed.time_hint || null;
  } catch {
    keywords = question.toLowerCase().split(/\W+/).filter(w => w.length > 2);
    factTypes = ['personal_info', 'preference', 'event'];
    timeHint = null;
  }

  const scored = facts.map(fact => ({
    ...fact,
    _score: scoreFact(fact, keywords, factTypes, timeHint),
  }));

  scored.sort((a, b) => b._score - a._score);
  return scored.slice(0, topK).filter(f => f._score > 0);
}
