# LongMemEval: ASMR-inspired Memory Benchmark

A standalone tool to benchmark conversational memory systems using the [LongMemEval](https://github.com/xiaowu0162/LongMemEval) dataset (ICLR 2025).

Implements a simplified version of [Supermemory's ASMR](https://supermemory.ai/research/) (Agentic Search and Memory Retrieval) technique using **JSONL files + grep-based search** — no vector DB, no RAG, no external services.

## Pipeline

```
Sessions → [Ingest] → facts.jsonl → [Search] → context → [Answer] → hypotheses.jsonl → [Evaluate] → score
```

| Stage | What it does | Model |
|-------|-------------|-------|
| **Ingest** | Extract structured facts from conversation sessions | Claude Haiku |
| **Search** | Find relevant facts for each question via keyword matching | Claude Haiku |
| **Answer** | Generate answers from retrieved context | Claude Haiku |
| **Evaluate** | Judge correctness against ground truth | GPT-4o |
| **Report** | Aggregate accuracy by question category | — |

## Quick Start

```bash
# 1. Set API keys
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...

# 2. Download dataset (~277MB + 15MB)
node run.mjs download

# 3. Run full pipeline
node run.mjs

# Or run individual stages
node ingest.mjs
node search.mjs
node answer.mjs
node evaluate.mjs
node report.mjs
```

## Cost Estimate

| Stage | Model | Calls | Est. Cost |
|-------|-------|-------|-----------|
| Ingest | Haiku | ~40 | ~$0.04 |
| Search | Haiku | ~500 | ~$0.08 |
| Answer | Haiku | ~500 | ~$0.30 |
| Evaluate | GPT-4o | ~500 | ~$1.50 |
| **Total** | | ~1,540 | **~$1.92** |

## Fact Schema (ASMR 6-vector)

Each extracted fact in `facts.jsonl` has:

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

## References

- [LongMemEval paper](https://arxiv.org/abs/2410.10813) (ICLR 2025)
- [LongMemEval dataset](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned)
- [Supermemory ASMR](https://blog.supermemory.ai/we-broke-the-frontier-in-agent-memory-introducing-99-sota-memory-system/)
- [MemoryBench](https://github.com/supermemoryai/memorybench)

## Requirements

- Node.js 18+ (uses built-in `fetch`)
- Anthropic API key (Claude Haiku)
- OpenAI API key (GPT-4o for evaluation)
