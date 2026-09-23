require "csv"
require "fileutils"
require_relative "emotion_rating"
require_relative "result_cache"
require_relative "stats"

# WRIME: Japanese social media posts, each rated 0-3 on eight emotions by the writer and by three readers.
# The readers' ratings are the target: they are what "sensing the other person's emotion from their words" means.
# Licensed CC BY-NC-ND, so the file stays in data/ and is not redistributed.
SOURCE_URL = "https://raw.githubusercontent.com/ids-cv/wrime/master/wrime-ver1.tsv"
SOURCE_PATH = File.join(__dir__, "data", "wrime", "wrime-ver1.tsv")
SAMPLE_SIZE = 500
SAMPLE_SEED = 42

EMOTIONS = EmotionRating::EMOTIONS
READERS = ["Reader1", "Reader2", "Reader3"].freeze

def download_source
  return if File.exist?(SOURCE_PATH)

  FileUtils.mkdir_p(File.dirname(SOURCE_PATH))
  system("curl", "-sL", "-o", SOURCE_PATH, SOURCE_URL, exception: true)
end

# The file is tab-separated with unescaped quotes inside posts, hence no quote character.
def load_test_posts
  CSV.read(SOURCE_PATH, col_sep: "\t", headers: true, quote_char: nil).select { |row| row["Train/Dev/Test"] == "test" }
end

def mean_of_raters(row, raters)
  EMOTIONS.to_h { |emotion| [emotion, raters.sum { |rater| Float(row.fetch("#{rater}_#{emotion}")) } / raters.size] }
end

def print_comparison(title, records, predicted_key, target_key)
  puts "\n#{title}"
  pairs_by_emotion = EMOTIONS.to_h do |emotion|
    [emotion, records.map { |record| [record.fetch(predicted_key).fetch(emotion), record.fetch(target_key).fetch(emotion)] }]
  end

  pairs_by_emotion.merge("all" => pairs_by_emotion.values.flatten(1)).each do |emotion, pairs|
    predicted, target = pairs.transpose
    puts format("  %-13s r=%.2f  mae=%.2f", emotion, Stats.pearson(predicted, target), Stats.mean_absolute_error(predicted, target))
  end
end

# An emotion counts as present when the readers rated it at least "weak" on average.
PRESENCE_THRESHOLD = 1.0

def auc_against(records, predicted_key, target_key, emotion)
  present, absent = records.partition { |record| record.fetch(target_key).fetch(emotion) >= PRESENCE_THRESHOLD }
  Stats.auc(present.map { |record| record.fetch(predicted_key).fetch(emotion) }, absent.map { |record| record.fetch(predicted_key).fetch(emotion) })
end

def print_ranking_quality(title, records)
  puts "\n#{title}"
  puts format("  %-13s %6s %7s %11s", "", "jev", "claude", "one reader")
  rows = EMOTIONS.map do |emotion|
    aucs = [auc_against(records, :jev, :readers, emotion), auc_against(records, :claude, :readers, emotion), auc_against(records, :one_reader, :other_readers, emotion)]
    puts format("  %-13s %6.3f %7.3f %11.3f", emotion, *aucs)
    aucs
  end
  puts format("  %-13s %6.3f %7.3f %11.3f", "mean", *rows.transpose.map { |column| column.sum / column.size })
end

download_source
posts = load_test_posts.sample(SAMPLE_SIZE, random: Random.new(SAMPLE_SEED))
texts = posts.map { |post| post.fetch("Sentence") }

jev_ratings = ResultCache.fetch("wrime_jev") { EmotionRating.by_jev(texts).map(&:to_h) }
claude_ratings = ResultCache.fetch("wrime_claude_#{ClaudeLabeler.model}") { EmotionRating.by_claude(texts, language: "Japanese") }

records = posts.zip(jev_ratings, claude_ratings).map do |post, jev_rating, claude_rating|
  {
    readers: mean_of_raters(post, READERS),
    writer: mean_of_raters(post, ["Writer"]),
    # One reader against the other two: how well a single person agrees with the rest, as a human reference.
    one_reader: mean_of_raters(post, ["Reader1"]),
    other_readers: mean_of_raters(post, READERS - ["Reader1"]),
    jev: jev_rating.fetch("scores"),
    claude: claude_rating
  }
end

print_comparison("jev vs the three readers' average", records, :jev, :readers)
print_comparison("claude #{ClaudeLabeler.model} vs the three readers' average", records, :claude, :readers)
print_comparison("human reference: one reader vs the other two readers' average", records, :one_reader, :other_readers)
print_comparison("the writer's own rating vs the three readers' average", records, :writer, :readers)
print_ranking_quality("ranking quality (auc): does the value rank posts where readers sensed the emotion above the rest?", records)

elapsed = jev_ratings.map { |rating| rating.fetch("elapsed") * 1000 }
puts format("\njev latency with eight score questions per request: p50=%dms p95=%dms", Stats.percentile(elapsed, 0.5), Stats.percentile(elapsed, 0.95))
