require 'coverage'
Coverage.start

quine = <<~CODE
  require 'coverage'
  Coverage.start
  quine = <<~CODE
  #{self.inspect}
  CODE
  executed = Coverage.result.values.first.each_with_index.map { |hits, i| i + 1 if hits&.positive? }.compact
  puts executed.map { |line| quine.lines[line - 1] }.join
CODE

executed = Coverage.result.values.first.each_with_index.map { |hits, i| i + 1 if hits&.positive? }.compact
puts executed.map { |line| quine.lines[line - 1] }.join
