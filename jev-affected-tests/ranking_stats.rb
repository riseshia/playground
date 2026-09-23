module RankingStats
  # Probability that a random positive outranks a random negative; ties count half.
  # Rank based, because the bootstrap calls this thousands of times.
  def self.auc(positives, negatives)
    ranked = (positives.map { |value| [value, true] } + negatives.map { |value| [value, false] }).sort_by(&:first)
    positive_rank_sum = 0.0
    index = 0
    while index < ranked.size
      tie_end = index
      tie_end += 1 while tie_end + 1 < ranked.size && ranked[tie_end + 1].first == ranked[index].first
      average_rank = (index + tie_end) / 2.0 + 1
      positive_rank_sum += average_rank * ranked[index..tie_end].count(&:last)
      index = tie_end + 1
    end

    (positive_rank_sum - positives.size * (positives.size + 1) / 2.0) / (positives.size * negatives.size)
  end

  # Share of positives selected when the cut-off lets through `budget` of the negatives.
  # Items tied at the cut-off are selected in proportion, which is what random tie-breaking gives on average.
  def self.recall_at_budget(positives, negatives, budget:)
    allowed = budget * negatives.size
    selected_positives = 0.0
    (positives + negatives).uniq.sort.reverse_each do |value|
      negatives_here = negatives.count(value)
      positives_here = positives.count(value)
      if negatives_here <= allowed
        allowed -= negatives_here
        selected_positives += positives_here
      else
        selected_positives += positives_here * allowed / negatives_here
        break
      end
    end

    selected_positives / positives.size
  end

  # Share of negatives that must be selected to reach `recall` of the positives. Lower is better.
  def self.budget_for_recall(positives, negatives, recall:)
    (0..100).map { |percent| percent / 100.0 }.find { |budget| recall_at_budget(positives, negatives, budget:) >= recall }
  end

  # Percentile interval over resampled clusters (spec files or source files),
  # because pairs sharing a file are not independent.
  def self.bootstrap_interval(clusters, resamples: 500, random: Random.new(1))
    estimates = Array.new(resamples) do
      yield Array.new(clusters.size) { clusters.sample(random:) }
    end.compact.sort

    [estimates.fetch((estimates.size * 0.025).floor), estimates.fetch((estimates.size * 0.975).ceil - 1)]
  end
end
