require_relative "claude_labeler"
require_relative "hf_dataset"
require_relative "jev"
require_relative "result_cache"

# Natural language inference on text written in each language, not translated:
# SNLI (en), JNLI (ja, from JGLUE) and KLUE-NLI (ko). The three sets are not parallel and differ in difficulty,
# so the figure to compare across languages is Jev's distance from the LLM on the same items.
SOURCES = {
  "en" => {dataset: "stanfordnlp/snli", config: "plain_text", split: "test"},
  "ja" => {dataset: "zenless-lab/jnli", config: "default", split: "test"},
  "ko" => {dataset: "klue/klue", config: "nli", split: "validation"}
}.freeze
LABELS = ["entailment", "neutral", "contradiction"].freeze
SAMPLE_SIZE = 500
# SNLI marks pairs its annotators could not agree on with -1; fetch a few extra to make up for them.
FETCH_SIZE = 520

INSTRUCTIONS = "Given the premise, what is the relation of the hypothesis to it?"
CRITERIA = {
  "entailment" => "The hypothesis must be true if the premise is true",
  "neutral" => "The hypothesis may or may not be true",
  "contradiction" => "The hypothesis cannot be true if the premise is true"
}.freeze

def load_pairs(source)
  HfDataset.load_rows(**source, limit: FETCH_SIZE).select { |row| LABELS[row.fetch("label")] }.first(SAMPLE_SIZE)
end

def accuracy(records, key)
  records.count { |record| record.fetch(key) == record.fetch(:gold) }.fdiv(records.size) * 100
end

pairs_by_language = SOURCES.transform_values { |source| load_pairs(source) }

jev_answers = ResultCache.fetch("nli_jev") do
  question = Jev.choice(INSTRUCTIONS, criteria: CRITERIA)
  pairs_by_language.transform_values do |pairs|
    jev = Jev.from_dotenv
    pairs.map { |pair| jev.ask(state: pair.slice("premise", "hypothesis"), questions: {relation: question}).answers.fetch("relation").slice("choice", "confidence") }
  end
end

claude_labels = ResultCache.fetch("nli_claude_#{ClaudeLabeler.model}") do
  labeler = ClaudeLabeler.new(instructions: "#{INSTRUCTIONS} #{CRITERIA.map { |label, meaning| "#{label}: #{meaning}." }.join(" ")}", answer_format: "one of: #{LABELS.join(", ")}")
  pairs_by_language.transform_values { |pairs| labeler.label(pairs.map { |pair| "premise: #{pair.fetch("premise")} / hypothesis: #{pair.fetch("hypothesis")}" }) }
end

puts "claude model: #{ClaudeLabeler.model}"
pairs_by_language.each do |language, pairs|
  records = pairs.zip(jev_answers.fetch(language), claude_labels.fetch(language)).map do |pair, jev_answer, claude_label|
    {gold: LABELS.fetch(pair.fetch("label")), jev: jev_answer.fetch("choice"), confidence: jev_answer.fetch("confidence"), claude: claude_label}
  end
  confident = records.select { |record| record.fetch(:confidence) >= 0.9 }

  puts format(
    "%s  jev=%.1f%%  claude=%.1f%%  gap=%.1f  | jev at confidence>=0.9: %.1f%% correct, %.0f%% of records  n=%d",
    language, accuracy(records, :jev), accuracy(records, :claude), accuracy(records, :claude) - accuracy(records, :jev),
    accuracy(confident, :jev), confident.size.fdiv(records.size) * 100, records.size
  )
end
