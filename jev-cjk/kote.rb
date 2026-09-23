require_relative "emotion_rating"
require_relative "hf_dataset"
require_relative "result_cache"
require_relative "stats"

# KOTE: Korean online comments tagged with any of 44 emotions by five raters.
# The Korean counterpart of wrime.rb. KOTE only says whether an emotion is present, so the 0-3 ratings
# are judged by ranking: do comments that carry the emotion get higher values than those that do not?
SAMPLE_SIZE = 500

# KOTE's label names, in the order of the dataset's label indexes.
KOTE_LABELS = [
  "불평/불만", "환영/호의", "감동/감탄", "지긋지긋", "고마움", "슬픔", "화남/분노", "존경", "기대감", "우쭐댐/무시함",
  "안타까움/실망", "비장함", "의심/불신", "뿌듯함", "편안/쾌적", "신기함/관심", "아껴주는", "부끄러움", "공포/무서움", "절망",
  "한심함", "역겨움/징그러움", "짜증", "어이없음", "없음", "패배/자기혐오", "귀찮음", "힘듦/지침", "즐거움/신남", "깨달음",
  "죄책감", "증오/혐오", "흐뭇함(귀여움/예쁨)", "당황/난처", "경악", "부담/안_내킴", "서러움", "재미없음", "불쌍함/연민", "놀람",
  "행복", "불안/걱정", "기쁨", "안심/신뢰"
].freeze

KOTE_LABELS_BY_EMOTION = {
  "Joy" => ["기쁨", "행복", "즐거움/신남"],
  "Sadness" => ["슬픔", "서러움"],
  "Anticipation" => ["기대감"],
  "Surprise" => ["놀람", "경악"],
  "Anger" => ["화남/분노", "짜증"],
  "Fear" => ["공포/무서움", "불안/걱정"],
  "Disgust" => ["역겨움/징그러움", "증오/혐오"],
  "Trust" => ["안심/신뢰"]
}.freeze

def present_emotions(row)
  tagged = row.fetch("labels").map { |index| KOTE_LABELS.fetch(index) }
  KOTE_LABELS_BY_EMOTION.select { |_, labels| labels.intersect?(tagged) }.keys
end

def print_ranking_quality(title, records, key)
  puts "\n#{title}"
  aucs = EmotionRating::EMOTIONS.map do |emotion|
    positives, negatives = records.partition { |record| record.fetch(:present).include?(emotion) }.map { |group| group.map { |record| record.fetch(key).fetch(emotion) } }
    auc = Stats.auc(positives, negatives)
    puts format("  %-13s auc=%.3f  carried by %.0f%% of comments", emotion, auc, positives.size.fdiv(records.size) * 100)
    auc
  end
  puts format("  %-13s auc=%.3f", "mean", aucs.sum / aucs.size)
end

rows = HfDataset.load_rows(dataset: "searle-j/kote", config: "dichotomized", split: "test", limit: SAMPLE_SIZE)
texts = rows.map { |row| row.fetch("text") }

jev_scores = ResultCache.fetch("kote_jev") { EmotionRating.by_jev(texts).map(&:scores) }
claude_ratings = ResultCache.fetch("kote_claude_#{ClaudeLabeler.model}") { EmotionRating.by_claude(texts, language: "Korean") }

records = rows.zip(jev_scores, claude_ratings).map do |row, jev_score, claude_rating|
  {present: present_emotions(row), jev: jev_score, claude: claude_rating}
end

print_ranking_quality("jev", records, :jev)
print_ranking_quality("claude #{ClaudeLabeler.model}", records, :claude)
