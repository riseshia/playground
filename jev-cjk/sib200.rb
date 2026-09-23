require "fileutils"
require "json"
require_relative "hf_dataset"
require_relative "jev"

# SIB-200: the same sentences translated into 200+ languages, labelled with one of seven topics.
# Rows share `index_id` across languages, so language is the only thing that varies.
DATASET = "Davlan/sib200"
CONFIGS = {"en" => "eng_Latn", "ja" => "jpn_Jpan", "ko" => "kor_Hang", "zh" => "zho_Hans"}.freeze
SPLITS = ["test", "validation", "train"].freeze
SAMPLE_SIZE = 500
# Larger than any split, so every row is loaded and rows can be matched by `index_id`.
SPLIT_ROW_LIMIT = 1_000

RESULTS_PATH = File.join(__dir__, "results", "sib200.json")

INSTRUCTIONS = {
  "en" => "Which topic is this sentence about?",
  "ja" => "この文はどの話題についてのものですか?",
  "ko" => "이 문장은 어떤 주제에 관한 것인가요?",
  "zh" => "这句话是关于哪个主题的?"
}.freeze

CRITERIA = {
  "en" => {
    "science/technology" => "Science or technology", "travel" => "Travel", "politics" => "Politics",
    "sports" => "Sports", "health" => "Health or medicine", "entertainment" => "Entertainment",
    "geography" => "Geography"
  },
  "ja" => {
    "science/technology" => "科学・技術", "travel" => "旅行", "politics" => "政治",
    "sports" => "スポーツ", "health" => "健康・医療", "entertainment" => "エンターテインメント",
    "geography" => "地理"
  },
  "ko" => {
    "science/technology" => "과학·기술", "travel" => "여행", "politics" => "정치",
    "sports" => "스포츠", "health" => "건강·의료", "entertainment" => "엔터테인먼트",
    "geography" => "지리"
  },
  "zh" => {
    "science/technology" => "科学技术", "travel" => "旅行", "politics" => "政治",
    "sports" => "体育", "health" => "健康与医疗", "entertainment" => "娱乐",
    "geography" => "地理"
  }
}.freeze

def load_rows(config)
  SPLITS.flat_map { |split| HfDataset.load_rows(dataset: DATASET, config:, split:, limit: SPLIT_ROW_LIMIT) }
end

def questions_for(language)
  ["en", language].uniq.to_h do |question_language|
    [question_language, Jev.choice(INSTRUCTIONS.fetch(question_language), criteria: CRITERIA.fetch(question_language))]
  end
end

def classify(jev, language, row)
  result = jev.ask(state: row.fetch("text"), questions: questions_for(language))
  {
    index_id: row.fetch("index_id"),
    language:,
    gold: row.fetch("category"),
    input_tokens: result.usage.fetch("input_tokens"),
    elapsed: result.elapsed,
    answers: result.answers.transform_values { |answer| answer.slice("choice", "confidence", "probabilities") }
  }
end

rows_by_language = CONFIGS.transform_values { |config| load_rows(config).to_h { |row| [row.fetch("index_id"), row] } }
sampled_ids = rows_by_language.fetch("en").keys.first(SAMPLE_SIZE)

# One thread per language: four kept-alive connections stay well under the 1,200 requests/minute limit.
records = CONFIGS.keys.map do |language|
  Thread.new do
    jev = Jev.from_dotenv
    sampled_ids.map { |index_id| classify(jev, language, rows_by_language.fetch(language).fetch(index_id)) }
  end
end.flat_map(&:value)

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.generate(records))
puts "wrote #{records.size} records to #{RESULTS_PATH}"
