require_relative "../jev-cjk/claude_labeler"
require_relative "dependency_map"
require_relative "jev_oracle"
require_relative "ranking_stats"

# Experiment 1: over (spec, source) pairs, does Jev rank the executed sources above the ones never executed?
# Positives are split by how the dependency could be spotted; negatives by how hard they are to rule out.
TEST_SAMPLE_SIZE = 300
PAIRS_PER_GROUP = 4
REPEAT_SIZE = 200
CLAUDE_TEST_SAMPLE_SIZE = 40
SEED = 20260921

Record = Data.define(:pair, :group, :scores)

dependency_map = DependencyMap.load
oracle = JevOracle.new(dependency_map:)
random = Random.new(SEED)

grouped_pairs_by_test = dependency_map.test_paths.sample(TEST_SAMPLE_SIZE, random:).to_h do |test_path|
  executed = dependency_map.sources_by_test.fetch(test_path).sort
  not_executed = dependency_map.source_paths - executed
  # A neighbour sits next to a source the spec really uses: app/services/a_service.rb when only b_service.rb ran.
  used_directories = executed.reject { |source_path| dependency_map.ubiquitous?(source_path) }.map { |source_path| File.dirname(source_path) }.uniq
  neighbours, strangers = not_executed.partition { |source_path| used_directories.include?(File.dirname(source_path)) }

  positives = executed.sample(PAIRS_PER_GROUP * 2, random:).map do |source_path|
    pair = Pair.new(test_path:, source_path:, executed: true)
    group = dependency_map.ubiquitous?(source_path) ? "ubiquitous" : "indirect"
    [pair, pair.name_matched? ? "name matched" : group]
  end
  negatives = {"neighbour" => neighbours, "stranger" => strangers}.flat_map do |group, source_paths|
    source_paths.sample(PAIRS_PER_GROUP, random:).map { |source_path| [Pair.new(test_path:, source_path:, executed: false), group] }
  end
  [test_path, positives + negatives]
end
oracle.ask_missing(grouped_pairs_by_test.values.flatten(1).map(&:first))

scorers = {
  "jev" => ->(pair) { oracle.score(pair) },
  "spec mentions the constant" => ->(pair) { dependency_map.read(pair.test_path).include?(pair.constant_name) ? 1.0 : 0.0 },
  "share of specs executing the source" => ->(pair) { dependency_map.executing_share(pair.source_path) }
}
records_by_test = grouped_pairs_by_test.values.map do |grouped_pairs|
  grouped_pairs.map { |pair, group| Record.new(pair:, group:, scores: scorers.transform_values { |scorer| scorer.call(pair) }) }
end

def auc_of(records, scorer_name, positive_group:, negative_group:)
  positives = records.select { |record| record.pair.executed && [nil, record.group].include?(positive_group) }
  negatives = records.select { |record| !record.pair.executed && [nil, record.group].include?(negative_group) }
  return if positives.empty? || negatives.empty?

  RankingStats.auc(positives.map { |record| record.scores.fetch(scorer_name) }, negatives.map { |record| record.scores.fetch(scorer_name) })
end

all_records = records_by_test.flatten
puts "specs=#{records_by_test.size}  pairs=#{all_records.size}  #{all_records.map(&:group).tally}"

[nil, "name matched", "indirect", "ubiquitous"].product([nil, "neighbour", "stranger"]).each do |positive_group, negative_group|
  puts "\npositives: #{positive_group || "all"}  vs  negatives: #{negative_group || "all"}"
  scorers.each_key do |scorer_name|
    estimate = auc_of(all_records, scorer_name, positive_group:, negative_group:)
    low, high = RankingStats.bootstrap_interval(records_by_test) { |resampled| auc_of(resampled.flatten, scorer_name, positive_group:, negative_group:) }
    puts format("  %-38s AUC %.3f  [%.3f, %.3f]", scorer_name, estimate, low, high)
  end
end

repeated = all_records.map(&:pair).sample(REPEAT_SIZE, random: Random.new(SEED))
repeat_cache_path = File.join(__dir__, "results/mastodon_jev_repeat.json")
File.write(repeat_cache_path, JSON.generate(repeated.to_h { |pair| [pair.key, oracle.ask_again(pair)] })) unless File.exist?(repeat_cache_path)
repeat_answers = JSON.parse(File.read(repeat_cache_path))
differences = repeated.map { |pair| (repeat_answers.fetch(pair.key) - oracle.score(pair)).abs }
puts format("\nrepeat of %d pairs: mean |difference| %.4f, max %.4f", repeated.size, differences.sum / differences.size, differences.max)

# How much of the dependency can be read off the text at all? A general-purpose LLM on the first specs of the same sample.
# Not a like-for-like contest: the LLM sees a spec's candidate sources side by side, Jev sees one pair per request.
claude_cache_path = File.join(__dir__, "results/mastodon_claude_#{ClaudeLabeler.model}.json")
unless File.exist?(claude_cache_path)
  answers = grouped_pairs_by_test.first(CLAUDE_TEST_SAMPLE_SIZE).each_slice(ClaudeLabeler::CONCURRENCY).flat_map do |slice|
    slice.map do |test_path, grouped_pairs|
      Thread.new do
        pairs = grouped_pairs.map(&:first)
        labeler = ClaudeLabeler.new(
          instructions: <<~INSTRUCTIONS,
            Below is an RSpec test file from a Rails application, followed by numbered source files from the same application.
            For each source file, estimate how likely it is that running the test file executes code defined in that source file, directly or indirectly.

            Test file #{test_path}:
            #{dependency_map.read(test_path)}
          INSTRUCTIONS
          answer_format: "an integer from 0 (certainly not executed) to 100 (certainly executed)"
        )
        pairs.map(&:key).zip(labeler.label(pairs.map { |pair| "#{pair.source_path}\n#{dependency_map.read(pair.source_path)}" }))
      end
    end.flat_map(&:value)
  end
  File.write(claude_cache_path, JSON.generate(answers.to_h))
end
claude_answers = JSON.parse(File.read(claude_cache_path))

claude_records_by_test = records_by_test.first(CLAUDE_TEST_SAMPLE_SIZE).map do |records|
  records.map { |record| record.with(scores: record.scores.merge("claude #{ClaudeLabeler.model}" => claude_answers.fetch(record.pair.key).to_f)) }
end
puts "\nfirst #{CLAUDE_TEST_SAMPLE_SIZE} specs, pairs=#{claude_records_by_test.flatten.size}"
[nil, "indirect", "ubiquitous"].each do |positive_group|
  puts "positives: #{positive_group || "all"}  vs  negatives: all"
  ["jev", "claude #{ClaudeLabeler.model}"].each do |scorer_name|
    estimate = auc_of(claude_records_by_test.flatten, scorer_name, positive_group:, negative_group: nil)
    low, high = RankingStats.bootstrap_interval(claude_records_by_test) { |resampled| auc_of(resampled.flatten, scorer_name, positive_group:, negative_group: nil) }
    puts format("  %-38s AUC %.3f  [%.3f, %.3f]", scorer_name, estimate, low, high)
  end
end
