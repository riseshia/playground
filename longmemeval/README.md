# LongMemEval: ASMR-lite Memory Provider

A standalone tool to benchmark conversational memory using the [LongMemEval](https://github.com/xiaowu0162/LongMemEval) dataset (ICLR 2025).

Implements a simplified version of [Supermemory's ASMR](https://supermemory.ai/research/) (Agentic Search and Memory Retrieval) technique using **JSONL + keyword search** — no vector DB, no RAG, no external services.

## Architecture

Each of the 500 questions in LongMemEval_s has its own independent haystack (~48 conversation sessions). The pipeline processes each question independently:

```
For each question:
  question.haystack_sessions → [Ingest] → facts[]
                                              ↓
                  question.question → [Search] → relevant facts
                                                      ↓
                            question.question → [Answer] → hypothesis
                                                                ↓
                          question.answer + hypothesis → [Evaluate] → correct/incorrect
```

| Stage | What it does | Model |
|-------|-------------|-------|
| **Ingest** | Extract structured facts from the question's haystack sessions | Claude Haiku (via `claude` CLI) |
| **Search** | LLM keyword extraction + scoring against facts | Claude Haiku (via `claude` CLI) |
| **Answer** | Generate answer from retrieved context | Claude Haiku (via `claude` CLI) |
| **Evaluate** | Judge correctness against ground truth | GPT-4o (via OpenRouter) |
| **Report** | Aggregate accuracy by question category | — |

## Quick Start

```bash
# Prerequisites: claude CLI installed and authenticated

# 1. Set OpenRouter key (for GPT-4o evaluation)
export OPENROUTER_API_KEY=sk-or-...

# 2. Download dataset (~277MB + 15MB)
node run.mjs download

# 3. Run full pipeline
node run.mjs

# Options
node run.mjs --limit 10    # Process only 10 questions (for testing)
node run.mjs --resume       # Resume from last checkpoint
```

## Cost Estimate

| Stage | Model | Calls | Est. Cost |
|-------|-------|-------|-----------|
| Ingest | Haiku | ~24,000 | ~$6.00 |
| Search | Haiku | ~500 | ~$0.08 |
| Answer | Haiku | ~500 | ~$0.30 |
| Evaluate | GPT-4o | ~500 | ~$1.50 |
| **Total** | | ~25,500 | **~$7.88** |

> Note: Ingest dominates cost because each question's ~48 sessions are processed independently. Claude CLI uses your local Max/Pro subscription, so actual cost may be $0 for Haiku calls.

## Fact Schema (ASMR 6-vector)

Each extracted fact has:

```json
{
  "id": "f_001",
  "session_id": "answer_280352e9",
  "date": "2023/05/30 (Tue) 11:27",
  "type": "personal_info",
  "fact": "User graduated with a Business Administration degree",
  "keywords": ["graduated", "business administration", "degree"]
}
```

Types: `personal_info`, `preference`, `event`, `temporal`, `update`, `assistant_info`

## Output

Results are written to `output/results.jsonl`. Each line contains:

```json
{
  "question_id": "multi-session_q001",
  "question_type": "multi-session",
  "question": "What is the user's name?",
  "expected": "Alex",
  "hypothesis": "Based on the memories, the user's name is Alex.",
  "label": true,
  "judge_response": "yes",
  "facts_extracted": 142,
  "facts_retrieved": 8
}
```

After all questions are processed, a report is printed with accuracy breakdown by category.

## References

- [LongMemEval paper](https://arxiv.org/abs/2410.10813) (ICLR 2025)
- [LongMemEval dataset](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned)
- [Supermemory ASMR](https://blog.supermemory.ai/we-broke-the-frontier-in-agent-memory-introducing-99-sota-memory-system/)
- [MemoryBench](https://github.com/supermemoryai/memorybench)

## Requirements

- Node.js 18+
- `claude` CLI (installed and authenticated — uses local subscription for Haiku calls)
- `OPENROUTER_API_KEY` environment variable (for GPT-4o evaluation)
