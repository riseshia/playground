module Stats
  def self.pearson(xs, ys)
    mean_x = xs.sum / xs.size
    mean_y = ys.sum / ys.size
    covariance = xs.zip(ys).sum { |x, y| (x - mean_x) * (y - mean_y) }
    covariance / Math.sqrt(xs.sum { |x| (x - mean_x)**2 } * ys.sum { |y| (y - mean_y)**2 })
  end

  def self.mean_absolute_error(xs, ys)
    xs.zip(ys).sum { |x, y| (x - y).abs } / xs.size
  end

  # Probability that a random positive gets a higher value than a random negative; ties count half.
  def self.auc(positives, negatives)
    wins = positives.sum { |positive| negatives.sum { |negative| positive > negative ? 1.0 : (positive == negative ? 0.5 : 0.0) } }
    wins / (positives.size * negatives.size)
  end

  def self.percentile(values, ratio)
    values.sort.fetch(((values.size - 1) * ratio).round)
  end
end
