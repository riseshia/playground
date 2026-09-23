require "json"

RESULTS_PATH = File.join(__dir__, "results", "sib200.json")
CONFIDENCE_BUCKETS = [0.0...0.5, 0.5...0.7, 0.7...0.9, 0.9..1.0].freeze

def correct?(record, question_language)
  record.fetch("answers").fetch(question_language).fetch("choice") == record.fetch("gold")
end

def percentile(values, ratio)
  values.sort.fetch(((values.size - 1) * ratio).round)
end

# Normal-approximation 95% interval; fine at n=500 and accuracies away from 0 and 1.
def margin(accuracy, size)
  1.96 * Math.sqrt(accuracy * (1 - accuracy) / size)
end

def print_accuracy(records_by_language)
  puts "accuracy (95% interval)"
  records_by_language.each do |language, records|
    ["en", language].uniq.each do |question_language|
      accuracy = records.count { |record| correct?(record, question_language) }.fdiv(records.size)
      puts format("  text=%s asked=%s  %.1f%% ±%.1f  n=%d", language, question_language, accuracy * 100, margin(accuracy, records.size) * 100, records.size)
    end
  end
end

def print_confidence_buckets(records_by_language)
  puts "\naccuracy by confidence bucket, English question (share of records in the bucket)"
  records_by_language.each do |language, records|
    cells = CONFIDENCE_BUCKETS.map do |bucket|
      inside = records.select { |record| bucket.cover?(record.fetch("answers").fetch("en").fetch("confidence")) }
      next format("%s: -", bucket) if inside.empty?

      format("%s: %.0f%% (%.0f%%)", bucket, inside.count { |record| correct?(record, "en") }.fdiv(inside.size) * 100, inside.size.fdiv(records.size) * 100)
    end
    puts "  #{language}  #{cells.join("   ")}"
  end
end

def print_agreement_with_english(records_by_language)
  english_choices = records_by_language.fetch("en").to_h { |record| [record.fetch("index_id"), record.fetch("answers").fetch("en").fetch("choice")] }

  puts "\nsame answer as the English text of the same sentence (English question)"
  records_by_language.except("en").each do |language, records|
    same = records.count { |record| record.fetch("answers").fetch("en").fetch("choice") == english_choices.fetch(record.fetch("index_id")) }
    puts format("  %s  %.1f%%", language, same.fdiv(records.size) * 100)
  end
end

def print_cost(records_by_language)
  puts "\nlatency and input tokens per request"
  records_by_language.each do |language, records|
    elapsed = records.map { |record| record.fetch("elapsed") * 1000 }
    tokens = records.sum { |record| record.fetch("input_tokens") }.fdiv(records.size)
    puts format("  %s  p50=%dms p95=%dms  tokens=%.0f  questions=%d", language, percentile(elapsed, 0.5), percentile(elapsed, 0.95), tokens, records.first.fetch("answers").size)
  end
end

records_by_language = JSON.parse(File.read(RESULTS_PATH)).group_by { |record| record.fetch("language") }

print_accuracy(records_by_language)
print_confidence_buckets(records_by_language)
print_agreement_with_english(records_by_language)
print_cost(records_by_language)
