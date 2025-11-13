require 'benchmark'
require 'fileutils'
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

# Generate test files
puts "\nGenerating #{ITERATIONS} test files..."
test_files = []
setup_time = Benchmark.realtime do
  ITERATIONS.times do |i|
    test_file = File.join(__dir__, "sample_#{i}.rb")
    FileUtils.cp(SAMPLE_FILE, test_file)
    test_files << test_file
  end
end
puts "Generated #{test_files.size} files in #{setup_time.round(3)} seconds"

begin
  results = {}

  puts "\n1. Testing Thread-based parallel processing..."
  thread_time = Benchmark.realtime do
    results[:thread] = ThreadParallel.run(test_files, THREAD_COUNT)
  end
  puts "   Completed in #{thread_time.round(3)} seconds"
  puts "   Results count: #{results[:thread].size}"

  puts "\n2. Testing Ractor-based parallel processing..."
  ractor_time = Benchmark.realtime do
    results[:ractor] = RactorParallel.run(test_files, RACTOR_COUNT)
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
ensure
  # Clean up test files
  puts "\nCleaning up test files..."
  cleanup_time = Benchmark.realtime do
    test_files.each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
  puts "Deleted #{test_files.size} files in #{cleanup_time.round(3)} seconds"
end
