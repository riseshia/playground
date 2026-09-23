require_relative "dependency_map"
require_relative "jev_oracle"
require_relative "ranking_stats"

# Experiment 2: affected_tests ignores an added source file, because the map has never seen it.
# Pretend each sampled source is new, rank the suite's specs for it, and see how many of the specs
# that really execute it are caught when only a slice of the suite is allowed to run.
SOURCE_SAMPLE_SIZE = 40
MIN_EXECUTING_TESTS = 5
MAX_POSITIVES = 40
NEGATIVE_SAMPLE_SIZE = 150
BUDGETS = [0.05, 0.1, 0.2].freeze
TARGET_RECALL = 0.95
SEED = 20260921

dependency_map = DependencyMap.load
oracle = JevOracle.new(dependency_map:)
random = Random.new(SEED)

eligible_sources = dependency_map.source_paths.select do |source_path|
  !dependency_map.ubiquitous?(source_path) && dependency_map.tests_by_source.fetch(source_path).size >= MIN_EXECUTING_TESTS
end
pairs_by_source = eligible_sources.sample(SOURCE_SAMPLE_SIZE, random:).to_h do |source_path|
  executing = dependency_map.tests_by_source.fetch(source_path).sort
  pairs = executing.sample(MAX_POSITIVES, random:).map { |test_path| Pair.new(test_path:, source_path:, executed: true) } +
    (dependency_map.test_paths - executing).sample(NEGATIVE_SAMPLE_SIZE, random:).map { |test_path| Pair.new(test_path:, source_path:, executed: false) }
  [source_path, pairs]
end
oracle.ask_missing(pairs_by_source.values.flatten)

mentions = ->(pair) { dependency_map.read(pair.test_path).include?(pair.constant_name) ? 1.0 : 0.0 }
scorers = {
  "jev" => ->(pair) { oracle.score(pair) },
  "spec mentions the constant" => mentions,
  "mention first, jev within ties" => ->(pair) { mentions.call(pair) + oracle.score(pair) },
  # Available for a new file too: the map already knows which specs touch half the application.
  "number of sources the spec executes" => ->(pair) { dependency_map.sources_by_test.fetch(pair.test_path).size.to_f }
}

def metrics_for(pairs, scorer)
  positives, negatives = pairs.partition(&:executed).map { |group| group.map(&scorer) }
  {
    "AUC" => RankingStats.auc(positives, negatives),
    **BUDGETS.to_h { |budget| ["recall at #{(budget * 100).round}% of the suite", RankingStats.recall_at_budget(positives, negatives, budget:)] },
    "suite share needed for #{(TARGET_RECALL * 100).round}% recall" => RankingStats.budget_for_recall(positives, negatives, recall: TARGET_RECALL)
  }
end

def report(title, pairs_by_source, scorers)
  puts "\n#{title}  (sources=#{pairs_by_source.size}, positives=#{pairs_by_source.values.flatten.count(&:executed)})"
  scorers.each do |name, scorer|
    metrics_by_source = pairs_by_source.values.map { |pairs| metrics_for(pairs, scorer) }
    puts "  #{name}"
    metrics_by_source.first.each_key do |metric|
      values = metrics_by_source.map { |metrics| metrics.fetch(metric) }
      low, high = RankingStats.bootstrap_interval(values) { |resampled| resampled.sum / resampled.size }
      puts format("    %-36s %.3f  [%.3f, %.3f]", metric, values.sum / values.size, low, high)
    end
  end
end

report("all executing specs", pairs_by_source, scorers)

# A budget is set per source above; a real selector needs one cut-off that works for every source.
puts "\none jev cut-off for every source"
all_pairs = pairs_by_source.values.flatten
[0.05, 0.1, 0.2, 0.3, 0.5].each do |cutoff|
  selected = all_pairs.select { |pair| oracle.score(pair) >= cutoff }
  puts format(
    "  jev >= %.2f  recall %.3f  share of non-executing specs selected %.3f",
    cutoff, selected.count(&:executed).fdiv(all_pairs.count(&:executed)), selected.count { |pair| !pair.executed }.fdiv(all_pairs.count { |pair| !pair.executed })
  )
end

puts "\nper source, worst first"
pairs_by_source.sort_by { |_, pairs| metrics_for(pairs, scorers.fetch("jev")).fetch("AUC") }.each do |source_path, pairs|
  puts format("  AUC %.3f  executing specs %3d  %s", metrics_for(pairs, scorers.fetch("jev")).fetch("AUC"), dependency_map.tests_by_source.fetch(source_path).size, source_path)
end

# The author of a new file writes its own spec anyway; what affected_tests would miss are the other specs.
beyond_own_spec = pairs_by_source.transform_values { |pairs| pairs.reject { |pair| pair.executed && pair.name_matched? } }
report("executing specs other than the source's own spec", beyond_own_spec, scorers)
