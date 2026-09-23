require "json"
require_relative "stats"

RESULTS_PATH = File.join(__dir__, "results", "miracl.json")

def reciprocal_rank(judged)
  ranked = judged.sort_by { |candidate| -candidate.fetch("noul") }
  1.0 / (ranked.index { |candidate| candidate.fetch("relevant") } + 1)
end

def ranking_quality(judged)
  relevant, irrelevant = judged.partition { |candidate| candidate.fetch("relevant") }.map { |group| group.map { |candidate| candidate.fetch("noul") } }
  Stats.auc(relevant, irrelevant)
end

def mean(values)
  values.sum / values.size
end

puts "reranking a pool of passages per query; chance level for 'top hit relevant' is the relevant share"
JSON.parse(File.read(RESULTS_PATH)).each do |language, pools|
  # MIRACL has queries none of whose 100 passages are relevant; there is nothing to rank for those.
  rankable = pools.select { |judged| judged.any? { |candidate| candidate.fetch("relevant") } }
  top_hit_relevant = rankable.count { |judged| judged.max_by { |candidate| candidate.fetch("noul") }.fetch("relevant") }

  puts format(
    "  %s  top hit relevant=%d/%d  mrr=%.2f  auc=%.3f  relevant share=%.0f%%  pool size=%.0f",
    language, top_hit_relevant, rankable.size, mean(rankable.map { |judged| reciprocal_rank(judged) }),
    mean(rankable.map { |judged| ranking_quality(judged) }),
    mean(rankable.map { |judged| judged.count { |candidate| candidate.fetch("relevant") }.fdiv(judged.size) }) * 100,
    mean(rankable.map { |judged| judged.size.to_f })
  )
end
