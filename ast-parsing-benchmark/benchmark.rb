require 'benchmark/ips'
require_relative 'thread_parallel'
require_relative 'ractor_parallel'

SAMPLE_FILE = File.join(__dir__, 'sample.rb')
ITERATIONS = 5000
THREAD_COUNT = 8
RACTOR_COUNT = 8

puts "=" * 80
puts "Ruby Prism AST Parsing Benchmark"
puts "=" * 80
puts "Sample file: #{SAMPLE_FILE}"
puts "Iterations: #{ITERATIONS}"
puts "Thread count: #{THREAD_COUNT}"
puts "Ractor count: #{RACTOR_COUNT}"
puts "=" * 80
puts

Benchmark.ips do |x|
  x.config(time: 10, warmup: 2)

  x.report("Thread-based (#{THREAD_COUNT} threads)") do
    ThreadParallel.run(SAMPLE_FILE, ITERATIONS, THREAD_COUNT)
  end

  x.report("Ractor-based (#{RACTOR_COUNT} ractors)") do
    RactorParallel.run(SAMPLE_FILE, ITERATIONS, RACTOR_COUNT)
  end

  x.compare!
end
