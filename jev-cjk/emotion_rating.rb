require_relative "claude_labeler"
require_relative "jev"

# Rates a short text on Plutchik's eight emotions, 0 (none) to 3 (strong), as a reader would sense them in the writer.
# Shared so that the Japanese and Korean experiments ask exactly the same thing.
module EmotionRating
  EMOTIONS = ["Joy", "Sadness", "Anticipation", "Surprise", "Anger", "Fear", "Disgust", "Trust"].freeze
  INTENSITY_LEVELS = ["None at all", "Weak", "Moderate", "Strong"].freeze

  Rated = Data.define(:scores, :elapsed)

  def self.by_jev(texts)
    jev = Jev.from_dotenv
    questions = EMOTIONS.to_h do |emotion|
      [emotion, Jev.score("How strongly would a reader sense #{emotion.downcase} in the person who wrote this post?", criteria: INTENSITY_LEVELS)]
    end

    texts.map do |text|
      result = jev.ask(state: text, questions:)
      Rated.new(scores: result.answers.transform_values { |answer| answer.fetch("score") }, elapsed: result.elapsed)
    end
  end

  def self.by_claude(texts, language:)
    labeler = ClaudeLabeler.new(
      instructions: "For each #{language} social media post, rate how strongly a reader would sense each emotion in the person who wrote it. " \
                    "0 = none at all, 1 = weak, 2 = moderate, 3 = strong.",
      answer_format: "an array of eight integers in the order [#{EMOTIONS.join(", ")}]"
    )
    labeler.label(texts).map { |values| EMOTIONS.zip(values.map(&:to_f)).to_h }
  end
end
