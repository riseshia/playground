require_relative "dependency_map"
require_relative "jev_oracle"
require_relative "packed_oracle"
require_relative "ranking_stats"

# Experiment 3: the selector as it would really run. A changed source the map does not know is ranked against
# every spec of the suite, many specs per request. Does packing keep the ranking, and what does one file cost?
#
# Step 1 picks the pack size on sources that step 2 never sees, so step 2's figures are not tuned on themselves.
# The rule was fixed before looking: the largest pack whose mean AUC stays within AUC_TOLERANCE of one pair per request.
EVALUATION_SOURCE_COUNT = 40
TUNING_SOURCE_COUNT = 10
MIN_EXECUTING_TESTS = 5
MAX_POSITIVES = 40
NEGATIVE_SAMPLE_SIZE = 150
PACK_SIZES = [5, 10, 20, 30].freeze
AUC_TOLERANCE = 0.02
BUDGETS = [0.05, 0.1, 0.2].freeze
TOP_COUNTS = [20, 50, 100].freeze
TARGET_RECALL = 0.95
DOLLARS_PER_MILLION_TOKENS = 0.042
SEED = 20260921

dependency_map = DependencyMap.load
single_oracle = JevOracle.new(dependency_map:)

eligible_sources = dependency_map.source_paths.select do |source_path|
  !dependency_map.ubiquitous?(source_path) && dependency_map.tests_by_source.fetch(source_path).size >= MIN_EXECUTING_TESTS
end
# Same draw as added_file.rb, so its one-pair-per-request answers serve as the control here.
evaluation_sources = eligible_sources.sample(EVALUATION_SOURCE_COUNT, random: Random.new(SEED))
tuning_sources = (eligible_sources - evaluation_sources).sample(TUNING_SOURCE_COUNT, random: Random.new(SEED + 1))

def mean(values) = values.sum / values.size

def split_scores(test_paths, source_path, dependency_map)
  executing = dependency_map.tests_by_source.fetch(source_path)
  test_paths.partition { |test_path| executing.include?(test_path) }.map { |group| group.map { |test_path| yield test_path } }
end

puts "step 1: pack size, on #{tuning_sources.size} tuning sources"
tuning_tests_by_source = tuning_sources.to_h do |source_path|
  random = Random.new(SEED)
  executing = dependency_map.tests_by_source.fetch(source_path).sort
  test_paths = executing.sample(MAX_POSITIVES, random:) + (dependency_map.test_paths - executing).sample(NEGATIVE_SAMPLE_SIZE, random:)
  [source_path, test_paths.shuffle(random:)]
end
single_oracle.ask_missing(tuning_tests_by_source.flat_map { |source_path, test_paths| test_paths.map { |test_path| Pair.new(test_path:, source_path:, executed: false) } })

single_auc = mean(tuning_tests_by_source.map do |source_path, test_paths|
  RankingStats.auc(*split_scores(test_paths, source_path, dependency_map) { |test_path| single_oracle.score(Pair.new(test_path:, source_path:, executed: false)) })
end)
puts format("  one pair per request   AUC %.3f", single_auc)

auc_by_pack_size = PACK_SIZES.to_h do |pack_size|
  packed_oracle = PackedOracle.new(dependency_map:, pack_size:)
  rankings = tuning_tests_by_source.map { |source_path, test_paths| [source_path, test_paths, packed_oracle.rank(source_path, test_paths)] }
  auc = mean(rankings.map { |source_path, test_paths, ranking| RankingStats.auc(*split_scores(test_paths, source_path, dependency_map) { |test_path| ranking.scores.fetch(test_path) }) })
  puts format("  up to %2d specs a request  AUC %.3f  requests per source %.1f", pack_size, auc, mean(rankings.map { |_, _, ranking| ranking.calls.to_f }))
  [pack_size, auc]
end
chosen_pack_size = PACK_SIZES.select { |pack_size| auc_by_pack_size.fetch(pack_size) >= single_auc - AUC_TOLERANCE }.max
abort "  no pack size stays within #{AUC_TOLERANCE} of one pair per request" if chosen_pack_size.nil?
puts "  chosen: up to #{chosen_pack_size} specs a request"

puts "\nstep 2: whole suite (#{dependency_map.test_paths.size} specs) for each of #{evaluation_sources.size} sources"
packed_oracle = PackedOracle.new(dependency_map:, pack_size: chosen_pack_size)
rankings_by_source = evaluation_sources.to_h do |source_path|
  [source_path, packed_oracle.rank(source_path, dependency_map.test_paths.shuffle(random: Random.new(SEED)))]
end

def report(metrics_by_source)
  metrics_by_source.first.each_key do |metric|
    values = metrics_by_source.map { |metrics| metrics.fetch(metric) }
    low, high = RankingStats.bootstrap_interval(values) { |resampled| mean(resampled) }
    puts format("    %-44s %8.3f  [%.3f, %.3f]", metric, mean(values), low, high)
  end
end

mentions = ->(source_path, test_path) { dependency_map.read(test_path).include?(Pair.new(test_path:, source_path:, executed: false).constant_name) ? 1.0 : 0.0 }
scorers = {
  "jev, packed" => ->(source_path, test_path) { rankings_by_source.fetch(source_path).scores.fetch(test_path) },
  "spec mentions the constant" => mentions,
  "number of sources the spec executes" => ->(_, test_path) { dependency_map.sources_by_test.fetch(test_path).size.to_f }
}
scorers.each do |name, scorer|
  puts "  #{name}"
  report(evaluation_sources.map do |source_path|
    positives, negatives = split_scores(dependency_map.test_paths, source_path, dependency_map) { |test_path| scorer.call(source_path, test_path) }
    {
      "AUC" => RankingStats.auc(positives, negatives),
      **BUDGETS.to_h { |budget| ["recall at #{(budget * 100).round}% of the suite", RankingStats.recall_at_budget(positives, negatives, budget:)] },
      "suite share needed for #{(TARGET_RECALL * 100).round}% recall" => RankingStats.budget_for_recall(positives, negatives, recall: TARGET_RECALL)
    }
  end)
end

puts "  jev, packed: what the first specs to run contain"
report(evaluation_sources.map do |source_path|
  executing = dependency_map.tests_by_source.fetch(source_path)
  ranked = rankings_by_source.fetch(source_path).scores.sort_by { |_, score| -score }.map(&:first)
  {
    **TOP_COUNTS.to_h { |count| ["share of executing specs in the first #{count}", (ranked.first(count) & executing).size.fdiv(executing.size)] },
    "position of the first executing spec" => ranked.index { |test_path| executing.include?(test_path) } + 1.0
  }
end)

puts "  cost of ranking the suite for one source"
report(rankings_by_source.values.map do |ranking|
  {
    "requests" => ranking.calls.to_f,
    "input tokens" => ranking.input_tokens.to_f,
    "dollars" => ranking.input_tokens * DOLLARS_PER_MILLION_TOKENS / 1_000_000,
    "seconds, #{PackedOracle::THREAD_COUNT} requests at a time" => ranking.seconds
  }
end)

puts "\npacked against one pair per request, on the pairs added_file.rb asked"
report(evaluation_sources.map do |source_path|
  shared = dependency_map.test_paths.select { |test_path| single_oracle.scored?(Pair.new(test_path:, source_path:, executed: false)) }
  {
    "AUC, one pair per request" => RankingStats.auc(*split_scores(shared, source_path, dependency_map) { |test_path| single_oracle.score(Pair.new(test_path:, source_path:, executed: false)) }),
    "AUC, packed" => RankingStats.auc(*split_scores(shared, source_path, dependency_map) { |test_path| rankings_by_source.fetch(source_path).scores.fetch(test_path) })
  }
end)

puts "\ndoes the place inside a request matter?"
["first half of the request", "second half of the request"].zip([0...0.5, 0.5..1]).each do |label, positions|
  report(evaluation_sources.filter_map do |source_path|
    ranking = rankings_by_source.fetch(source_path)
    placed = dependency_map.test_paths.select { |test_path| positions.cover?(ranking.positions.fetch(test_path)) }
    positives, negatives = split_scores(placed, source_path, dependency_map) { |test_path| ranking.scores.fetch(test_path) }
    next if positives.empty?

    {"AUC, #{label}" => RankingStats.auc(positives, negatives), "mean value given to non-executing specs, #{label}" => mean(negatives)}
  end)
end

puts "\none cut-off for every source, whole suite"
judged = evaluation_sources.flat_map do |source_path|
  executing = dependency_map.tests_by_source.fetch(source_path)
  rankings_by_source.fetch(source_path).scores.map { |test_path, score| [score, executing.include?(test_path)] }
end
[0.05, 0.1, 0.2, 0.3, 0.5].each do |cutoff|
  selected = judged.select { |score, _| score >= cutoff }
  puts format(
    "  jev >= %.2f  recall %.3f  share of non-executing specs selected %.3f  specs selected per source %.0f",
    cutoff, selected.count(&:last).fdiv(judged.count(&:last)), selected.count { |_, executed| !executed }.fdiv(judged.count { |_, executed| !executed }), selected.size.fdiv(evaluation_sources.size)
  )
end
