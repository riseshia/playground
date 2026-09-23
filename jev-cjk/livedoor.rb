require "fileutils"
require_relative "claude_labeler"
require_relative "jev"
require_relative "result_cache"

# livedoor news corpus: Japanese articles written by Japanese editors, grouped by the nine sites they ran on.
# The Japanese counterpart of klue_ynat.rb: native text, and the headline is all the model gets.
ARCHIVE_URL = "https://www.rondhuit.com/download/ldcc-20140209.tar.gz"
CORPUS_DIR = File.join(__dir__, "data", "livedoor")
SAMPLE_SIZE = 500
SAMPLE_SEED = 42
# Each article file is: URL, timestamp, headline, then the body.
HEADLINE_LINE = 2

SITES = {
  "dokujo-tsushin" => "Columns for single women: love, marriage, work and life",
  "it-life-hack" => "IT tips: PC software, web services, security, gadgets for work",
  "kaden-channel" => "Home electronics and appliances",
  "livedoor-homme" => "Men's lifestyle: career, fashion, food, hobbies",
  "movie-enter" => "Movies: releases, trailers, interviews, film events",
  "peachy" => "Women's lifestyle: beauty, fashion, food, romance",
  "smax" => "Smartphones and mobile: handsets, carriers, apps, accessories",
  "sports-watch" => "Sports",
  "topic-news" => "Trending general news and online talk"
}.freeze

INSTRUCTIONS = "Which livedoor news site did this Japanese headline run on?"

Article = Data.define(:id, :site, :headline)

def download_corpus
  return if Dir.exist?(File.join(CORPUS_DIR, "text"))

  FileUtils.mkdir_p(CORPUS_DIR)
  archive_path = File.join(CORPUS_DIR, "ldcc.tar.gz")
  system("curl", "-sL", "-o", archive_path, ARCHIVE_URL, exception: true)
  system("tar", "xzf", archive_path, "-C", CORPUS_DIR, exception: true)
end

def load_articles
  SITES.keys.flat_map do |site|
    Dir.glob(File.join(CORPUS_DIR, "text", site, "#{site}-*.txt")).sort.map do |path|
      Article.new(id: File.basename(path, ".txt"), site:, headline: File.readlines(path, chomp: true).fetch(HEADLINE_LINE))
    end
  end
end

def accuracy(records, key)
  records.count { |record| record.fetch(key) == record.fetch(:gold) }.fdiv(records.size) * 100
end

download_corpus
articles = load_articles.sample(SAMPLE_SIZE, random: Random.new(SAMPLE_SEED))
headlines = articles.map(&:headline)

jev_answers = ResultCache.fetch("livedoor_jev") do
  jev = Jev.from_dotenv
  question = Jev.choice(INSTRUCTIONS, criteria: SITES)
  headlines.map { |headline| jev.ask(state: headline, questions: {site: question}).answers.fetch("site").slice("choice", "confidence") }
end

claude_labels = ResultCache.fetch("livedoor_claude_#{ClaudeLabeler.model}") do
  site_list = SITES.map { |site, description| "#{site} (#{description})" }.join(", ")
  ClaudeLabeler.new(instructions: INSTRUCTIONS, answer_format: "the site name only, one of: #{site_list}").label(headlines)
end

records = articles.zip(jev_answers, claude_labels).map do |article, jev_answer, claude_label|
  {gold: article.site, jev: jev_answer.fetch("choice"), confidence: jev_answer.fetch("confidence"), claude: claude_label.to_s[/\A[\w-]+/]}
end

puts format("jev     %.1f%%  n=%d", accuracy(records, :jev), records.size)
puts format("claude %s  %.1f%%", ClaudeLabeler.model, accuracy(records, :claude))
puts format("jev agrees with claude on %.1f%%", records.count { |record| record.fetch(:jev) == record.fetch(:claude) }.fdiv(records.size) * 100)

confident = records.select { |record| record.fetch(:confidence) >= 0.9 }
puts format("jev at confidence >= 0.9: %.1f%% correct, %.0f%% of records", accuracy(confident, :jev), confident.size.fdiv(records.size) * 100)

puts "\njev confusions (gold -> predicted)"
records.reject { |record| record.fetch(:jev) == record.fetch(:gold) }
  .map { |record| "#{record.fetch(:gold)} -> #{record.fetch(:jev)}" }
  .tally.sort_by { |_, count| -count }.first(8)
  .each { |confusion, count| puts "  #{confusion}: #{count}" }
