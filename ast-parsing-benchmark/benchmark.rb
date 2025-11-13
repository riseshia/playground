require 'benchmark'
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

results = {}

puts "\n1. Testing Thread-based parallel processing..."
thread_time = Benchmark.realtime do
  results[:thread] = ThreadParallel.run(SAMPLE_FILE, ITERATIONS, THREAD_COUNT)
end
puts "   Completed in #{thread_time.round(3)} seconds"
puts "   Results count: #{results[:thread].size}"

puts "\n2. Testing Ractor-based parallel processing..."
ractor_time = Benchmark.realtime do
  results[:ractor] = RactorParallel.run(SAMPLE_FILE, ITERATIONS, RACTOR_COUNT)
end
puts "   Completed in #{ractor_time.round(3)} seconds"
puts "   Results count: #{results[:ractor].size}"

puts "\n" + "=" * 80
puts "COMPARISON"
puts "=" * 80
puts "Thread-based: #{thread_time.round(3)}s"
puts "Ractor-based: #{ractor_time.round(3)}s"

if thread_time < ractor_time
  speedup = (ractor_time / thread_time).round(2)
  puts "\n✓ Thread-based is #{speedup}x faster"
else
  speedup = (thread_time / ractor_time).round(2)
  puts "\n✓ Ractor-based is #{speedup}x faster"
end
puts "=" * 80
