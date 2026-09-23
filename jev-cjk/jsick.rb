require "fileutils"
require "json"
require_relative "hf_dataset"
require_relative "jev"
require_relative "stats"

# JSICK: the SICK sentence pairs translated into Japanese by hand and then re-annotated in Japanese,
# so each pair carries an English and a Japanese version, each with its own inference label and 1-5 relatedness.
# The `stress` set rewrites the Japanese premise (drops or reorders case particles) to see whether a model
# still reads who did what.
DATASET = "hpprc/jsick"
LABELS = ["entailment", "neutral", "contradiction"].freeze
SAMPLE_SIZE = 500
RESULTS_PATH = File.join(__dir__, "results", "jsick.json")

QUESTIONS = {
  relation: Jev.choice(
    "Given the premise, what is the relation of the hypothesis to it?",
    criteria: {
      "entailment" => "The hypothesis must be true if the premise is true",
      "neutral" => "The hypothesis may or may not be true",
      "contradiction" => "The hypothesis cannot be true if the premise is true"
    }
  ),
  relatedness: Jev.score(
    "How related in meaning are the premise and the hypothesis?",
    criteria: ["Completely unrelated", "Mostly unrelated", "Somewhat related", "Mostly the same meaning", "The same meaning"]
  )
}.freeze
# JSICK rates relatedness from 1 to 5; the score question's levels are numbered from 0.
RELATEDNESS_OFFSET = 1

Pair = Data.define(:premise, :hypothesis, :label, :relatedness, :group)

def judge(jev, pair)
  answers = jev.ask(state: {premise: pair.premise, hypothesis: pair.hypothesis}, questions: QUESTIONS).answers
  {
    group: pair.group,
    gold: pair.label,
    predicted: answers.fetch("relation").fetch("choice"),
    confidence: answers.fetch("relation").fetch("confidence"),
    gold_relatedness: pair.relatedness,
    predicted_relatedness: answers.fetch("relatedness").fetch("score") + RELATEDNESS_OFFSET
  }
end

def print_summary(title, records)
  accuracy = records.count { |record| record.fetch(:predicted) == record.fetch(:gold) }.fdiv(records.size) * 100
  relatedness = Stats.pearson(records.map { |record| record.fetch(:predicted_relatedness) }, records.map { |record| record.fetch(:gold_relatedness) })
  puts format("  %-28s nli=%.1f%%  relatedness r=%.2f  n=%d", title, accuracy, relatedness, records.size)
end

base_rows = HfDataset.load_rows(dataset: DATASET, config: "base", split: "test", limit: SAMPLE_SIZE)
stress_rows = HfDataset.load_rows(dataset: DATASET, config: "stress", split: "test", limit: SAMPLE_SIZE)

pairs_by_run = {
  "en" => base_rows.map { |row| Pair.new(premise: row.fetch("premise_en"), hypothesis: row.fetch("hypothesis_en"), label: LABELS.fetch(row.fetch("label_en")), relatedness: row.fetch("score_en"), group: "en") },
  "ja" => base_rows.map { |row| Pair.new(premise: row.fetch("premise"), hypothesis: row.fetch("hypothesis"), label: LABELS.fetch(row.fetch("label")), relatedness: row.fetch("score"), group: "ja") },
  "ja_stress" => stress_rows.map { |row| Pair.new(premise: row.fetch("premise"), hypothesis: row.fetch("hypothesis"), label: LABELS.fetch(row.fetch("label")), relatedness: row.fetch("score"), group: row.fetch("rephrase_type")) }
}

records_by_run = pairs_by_run.map do |run, pairs|
  Thread.new do
    jev = Jev.from_dotenv
    [run, pairs.map { |pair| judge(jev, pair) }]
  end
end.to_h(&:value)

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.generate(records_by_run))

puts "same pairs, English and Japanese versions"
print_summary("en", records_by_run.fetch("en"))
print_summary("ja", records_by_run.fetch("ja"))

puts "\nJapanese premise rewritten, by rewrite type"
records_by_run.fetch("ja_stress").group_by { |record| record.fetch(:group) }.sort.each { |type, records| print_summary("rewrite type #{type}", records) }
