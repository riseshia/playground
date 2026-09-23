require "json"
require "open3"

# Labels the same items with a general-purpose LLM through the `claude` CLI.
# A Jev accuracy means little on its own when the gold labels are noisy; this gives the ceiling to compare with.
class ClaudeLabeler
  BATCH_SIZE = 25
  CONCURRENCY = 8
  MAX_ATTEMPTS = 5

  # `CLAUDE_MODEL=haiku ruby nli.rb` reruns only the baseline, with another model.
  def self.model = ENV.fetch("CLAUDE_MODEL", "sonnet")

  # `answer_format` describes what one item's answer looks like, e.g. "one of: a, b, c".
  def initialize(instructions:, answer_format:)
    @instructions = instructions
    @answer_format = answer_format
  end

  def label(items)
    items.each_slice(BATCH_SIZE).each_slice(CONCURRENCY).flat_map do |batches|
      batches.map { |batch| Thread.new { label_batch(batch) } }.flat_map(&:value)
    end
  end

  private

  # Keyed by item number rather than a bare array: with an array the model occasionally drops one item
  # and every later label silently shifts by one.
  def label_batch(items)
    prompt = <<~PROMPT
      #{@instructions}
      Answer for each item: #{@answer_format}
      Reply with only a JSON object mapping each item number to its answer, like {"1": ..., "2": ...}.

      #{items.each_with_index.map { |item, index| "#{index + 1}. #{item}" }.join("\n")}
    PROMPT
    expected_keys = (1..items.size).map(&:to_s)

    MAX_ATTEMPTS.times do
      output, status = Open3.capture2("claude", "-p", prompt, "--model", self.class.model)
      raise "claude exited with #{status.exitstatus}" unless status.success?

      labels = parse_labels(output)
      return labels.values_at(*expected_keys) if labels.keys.sort == expected_keys.sort
    end

    raise "claude kept returning something other than labels for the #{items.size} items it was given"
  end

  # Items that contain code tempt the model into prose around the JSON; treat that like any other malformed answer.
  def parse_labels(output)
    JSON.parse(output[/\{.*\}/m] || "{}")
  rescue JSON::ParserError
    {}
  end
end
