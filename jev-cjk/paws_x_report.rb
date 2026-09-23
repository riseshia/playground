require "json"

RESULTS_PATH = File.join(__dir__, "results", "paws_x.json")
NOUL_BUCKETS = [0.0...0.2, 0.2...0.4, 0.4...0.6, 0.6...0.8, 0.8..1.0].freeze

def accuracy(records, question_language)
  records.count { |record| (record.fetch("nouls").fetch(question_language) > 0.5) == record.fetch("gold") }.fdiv(records.size)
end

# Probability that a random paraphrase pair gets a higher value than a random non-paraphrase pair.
# Unlike accuracy it does not depend on where the 0.5 cut happens to fall for a language.
def ranking_quality(records, question_language)
  positives, negatives = records.partition { |record| record.fetch("gold") }.map { |group| group.map { |record| record.fetch("nouls").fetch(question_language) } }
  wins = positives.sum { |positive| negatives.sum { |negative| positive > negative ? 1.0 : (positive == negative ? 0.5 : 0.0) } }
  wins / (positives.size * negatives.size)
end

def best_cut_accuracy(records, question_language)
  (1..19).map { |step| step / 20.0 }.map do |cut|
    [cut, records.count { |record| (record.fetch("nouls").fetch(question_language) > cut) == record.fetch("gold") }.fdiv(records.size)]
  end.max_by(&:last)
end

records_by_language = JSON.parse(File.read(RESULTS_PATH)).group_by { |record| record.fetch("language") }

puts "accuracy at 0.5 / ranking quality (AUC) / best cut and its accuracy / share of true paraphrases"
records_by_language.each do |language, records|
  ["en", language].uniq.each do |question_language|
    cut, cut_accuracy = best_cut_accuracy(records, question_language)
    puts format(
      "  text=%s asked=%s  acc=%.1f%%  auc=%.3f  best cut=%.2f -> %.1f%%  positives=%.0f%%  n=%d",
      language, question_language, accuracy(records, question_language) * 100, ranking_quality(records, question_language),
      cut, cut_accuracy * 100, records.count { |record| record.fetch("gold") }.fdiv(records.size) * 100, records.size
    )
  end
end

puts "\ncalibration, English question: share of true paraphrases inside each noul bucket (share of records)"
records_by_language.each do |language, records|
  cells = NOUL_BUCKETS.map do |bucket|
    inside = records.select { |record| bucket.cover?(record.fetch("nouls").fetch("en")) }
    next format("%s: -", bucket) if inside.empty?

    format("%s: %.0f%% (%.0f%%)", bucket, inside.count { |record| record.fetch("gold") }.fdiv(inside.size) * 100, inside.size.fdiv(records.size) * 100)
  end
  puts "  #{language}  #{cells.join("   ")}"
end
