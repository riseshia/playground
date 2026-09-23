require "json"
require_relative "claude_labeler"
require_relative "hf_dataset"
require_relative "result_cache"

# The same 500 headlines as klue_ynat.rb, labelled by a general-purpose LLM. Run klue_ynat.rb first.
LABELS = ["IT과학", "경제", "사회", "생활문화", "세계", "스포츠", "정치"].freeze
SAMPLE_SIZE = 500
JEV_RESULTS_PATH = File.join(__dir__, "results", "klue_ynat.json")

rows = HfDataset.load_rows(dataset: "klue/klue", config: "ynat", split: "validation", limit: SAMPLE_SIZE)

labels = ResultCache.fetch("klue_ynat_claude_#{ClaudeLabeler.model}") do
  labeler = ClaudeLabeler.new(instructions: "Which section of a Korean news site would each headline appear in?", answer_format: "one of: #{LABELS.join(", ")}")
  labeler.label(rows.map { |row| row.fetch("title") })
end

records = rows.zip(labels).map { |row, label| {guid: row.fetch("guid"), gold: LABELS.fetch(row.fetch("label")), claude: label} }

correct = records.count { |record| record.fetch(:claude) == record.fetch(:gold) }
puts format("claude %s  %.1f%%  n=%d", ClaudeLabeler.model, correct.fdiv(records.size) * 100, records.size)

jev_choices = JSON.parse(File.read(JEV_RESULTS_PATH)).to_h { |record| [record.fetch("guid"), record.fetch("answers").fetch("en").fetch("choice")] }
agreed = records.count { |record| record.fetch(:claude) == jev_choices.fetch(record.fetch(:guid)) }
puts format("jev agrees with claude on  %.1f%%", agreed.fdiv(records.size) * 100)
