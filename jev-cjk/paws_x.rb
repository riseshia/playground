require "fileutils"
require "json"
require_relative "hf_dataset"
require_relative "jev"

# PAWS-X: sentence pairs with heavy word overlap, labelled as paraphrase or not, translated from
# the same English test set. Word order carries the answer, which is where ja/ko differ most from en.
DATASET = "google-research-datasets/paws-x"
LANGUAGES = ["en", "ja", "ko", "zh"].freeze
SAMPLE_SIZE = 500
RESULTS_PATH = File.join(__dir__, "results", "paws_x.json")

INSTRUCTIONS = {
  "en" => "Do sentence1 and sentence2 mean the same thing?",
  "ja" => "sentence1とsentence2は同じ意味ですか?",
  "ko" => "sentence1과 sentence2는 같은 뜻인가요?",
  "zh" => "sentence1和sentence2的意思相同吗?"
}.freeze

def judge(jev, language, row)
  questions = ["en", language].uniq.to_h { |question_language| [question_language, Jev.noul(INSTRUCTIONS.fetch(question_language))] }
  result = jev.ask(state: row.slice("sentence1", "sentence2"), questions:)
  {
    id: row.fetch("id"),
    language:,
    gold: row.fetch("label") == 1,
    nouls: result.answers.transform_values { |answer| answer.fetch("noul") }
  }
end

records = LANGUAGES.map do |language|
  Thread.new do
    jev = Jev.from_dotenv
    rows = HfDataset.load_rows(dataset: DATASET, config: language, split: "test", limit: SAMPLE_SIZE)
    # Some translated rows are empty in the published dataset.
    rows.reject { |row| row.fetch("sentence1").empty? || row.fetch("sentence2").empty? }.map { |row| judge(jev, language, row) }
  end
end.flat_map(&:value)

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.generate(records))
puts "wrote #{records.size} records to #{RESULTS_PATH}"
