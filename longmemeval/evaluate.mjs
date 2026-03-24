// Stage 4: Evaluate — Judge answer correctness via OpenRouter.
// Ported from LongMemEval's evaluate_qa.py.

import { callOpenRouter } from './lib.mjs';

// ─── Prompt Templates (from evaluate_qa.py) ─────────────────────────

const PROMPTS = {
  standard: `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response is equivalent to the correct answer or contains all the intermediate steps to get the correct answer, you should also answer yes. If the response only contains a subset of the information required by the answer, answer no. \n\nQuestion: {question}\n\nCorrect Answer: {answer}\n\nModel Response: {hypothesis}\n\nIs the model response correct? Answer yes or no only.`,

  'temporal-reasoning': `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response is equivalent to the correct answer or contains all the intermediate steps to get the correct answer, you should also answer yes. If the response only contains a subset of the information required by the answer, answer no. In addition, do not penalize off-by-one errors for the number of days. If the question asks for the number of days/weeks/months, etc., and the model makes off-by-one errors (e.g., predicting 19 days when the answer is 18), the model's response is still correct. \n\nQuestion: {question}\n\nCorrect Answer: {answer}\n\nModel Response: {hypothesis}\n\nIs the model response correct? Answer yes or no only.`,

  'knowledge-update': `I will give you a question, a correct answer, and a response from a model. Please answer yes if the response contains the correct answer. Otherwise, answer no. If the response contains some previous information along with an updated answer, the response should be considered as correct as long as the updated answer is the required answer.\n\nQuestion: {question}\n\nCorrect Answer: {answer}\n\nModel Response: {hypothesis}\n\nIs the model response correct? Answer yes or no only.`,

  'single-session-preference': `I will give you a question, a rubric for desired personalized response, and a response from a model. Please answer yes if the response satisfies the desired response. Otherwise, answer no. The model does not need to reflect all the points in the rubric. The response is correct as long as it recalls and utilizes the user's personal information correctly.\n\nQuestion: {question}\n\nRubric: {answer}\n\nModel Response: {hypothesis}\n\nIs the model response correct? Answer yes or no only.`,

  abstention: `I will give you an unanswerable question, an explanation, and a response from a model. Please answer yes if the model correctly identifies the question as unanswerable. The model could say that the information is incomplete, or some other information is given but the asked information is not.\n\nQuestion: {question}\n\nExplanation: {answer}\n\nModel Response: {hypothesis}\n\nDoes the model correctly identify the question as unanswerable? Answer yes or no only.`,
};

/**
 * Evaluate a single hypothesis against the ground truth.
 * @returns {Promise<{label: boolean, judgeResponse: string}>}
 */
export async function evaluate({ questionType, questionId, question, answer, hypothesis }) {
  const isAbstention = questionId.includes('_abs');

  let template;
  if (isAbstention) {
    template = PROMPTS.abstention;
  } else if (PROMPTS[questionType]) {
    template = PROMPTS[questionType];
  } else {
    template = PROMPTS.standard;
  }

  const prompt = template
    .replace('{question}', question)
    .replace('{answer}', answer)
    .replace('{hypothesis}', hypothesis);

  const response = await callOpenRouter(prompt);
  const label = response.toLowerCase().includes('yes');

  return { label, judgeResponse: response };
}
