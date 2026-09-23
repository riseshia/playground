require "fileutils"
require "json"
require_relative "hf_dataset"
require_relative "jev"

# KLUE-YNAT: Korean news headlines written by Korean editors, seven topics.
# Unlike the translated benchmarks this is native text, and a headline is all the model gets.
LABELS = ["IT과학", "경제", "사회", "생활문화", "세계", "스포츠", "정치"].freeze
SAMPLE_SIZE = 500
RESULTS_PATH = File.join(__dir__, "results", "klue_ynat.json")

QUESTIONS = {
  "en" => Jev.choice(
    "Which section of a Korean news site would this headline appear in?",
    criteria: {
      "IT과학" => "IT and science", "경제" => "Economy and business", "사회" => "Society and domestic affairs",
      "생활문화" => "Lifestyle and culture", "세계" => "World news", "스포츠" => "Sports", "정치" => "Politics"
    }
  ),
  "ko" => Jev.choice(
    "이 제목은 한국 뉴스 사이트의 어느 섹션에 실릴 기사인가요?",
    criteria: {
      "IT과학" => "IT·과학", "경제" => "경제·산업", "사회" => "사회·국내 사건", "생활문화" => "생활·문화",
      "세계" => "국제 뉴스", "스포츠" => "스포츠", "정치" => "정치"
    }
  )
}.freeze

jev = Jev.from_dotenv
rows = HfDataset.load_rows(dataset: "klue/klue", config: "ynat", split: "validation", limit: SAMPLE_SIZE)

records = rows.map do |row|
  result = jev.ask(state: row.fetch("title"), questions: QUESTIONS)
  {
    guid: row.fetch("guid"),
    gold: LABELS.fetch(row.fetch("label")),
    answers: result.answers.transform_values { |answer| answer.slice("choice", "confidence") }
  }
end

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.generate(records))

QUESTIONS.each_key do |question_language|
  correct = records.count { |record| record.fetch(:answers).fetch(question_language).fetch("choice") == record.fetch(:gold) }
  puts format("asked=%s  %.1f%%  n=%d", question_language, correct.fdiv(records.size) * 100, records.size)
end

puts "\nconfusions, English question (gold -> predicted)"
records.reject { |record| record.fetch(:answers).fetch("en").fetch("choice") == record.fetch(:gold) }
  .map { |record| "#{record.fetch(:gold)} -> #{record.fetch(:answers).fetch("en").fetch("choice")}" }
  .tally.sort_by { |_, count| -count }.first(8)
  .each { |confusion, count| puts "  #{confusion}: #{count}" }
