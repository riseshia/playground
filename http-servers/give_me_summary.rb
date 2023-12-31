require 'json'

def format(result)
  process_count = result.process_count
  worker_per_process_count = result.worker_per_process_count
  if result.name == 'multi_threaded'
    process_count = 1
  elsif result.name == 'single_threaded'
    process_count = 1
    worker_per_process_count = 1
  elsif result.name == 'prefork'
    worker_per_process_count = 1
  end

  formatted_name = "#{process_count} cpu, #{worker_per_process_count} workers"

  metrics = result.metrics
  rps = metrics["iterations"]["rate"]
  iteration_duration = metrics["iteration_duration"]
  col = []
  col << formatted_name.ljust(20)
  col << rps.to_i.to_s.rjust(5)
  col << iteration_duration['avg'].to_i.to_s.rjust(5)
  col << iteration_duration['med'].to_i.to_s.rjust(5)
  col << iteration_duration['p(90)'].to_i.to_s.rjust(5)
  col << iteration_duration['p(95)'].to_i.to_s.rjust(5)
  col << iteration_duration['min'].to_i.to_s.rjust(5)
  col << iteration_duration['max'].to_i.to_s.rjust(5)

  puts col.join(' ')
end

grouped_servers = Hash.new { |h, k| h[k] = [] }

Result = Struct.new(:name, :process_count, :worker_per_process_count, :load_type, :metrics, keyword_init: true)

Dir["reports/*.json"].each do |file|
  json = JSON.parse(File.read(file))
  filename = file.split('/').last.split('.').first
  name, process_count, worker_per_process_count, load_type = filename.split('-')
  result = Result.new(
    name: name,
    process_count: process_count.sub('0', ' '),
    worker_per_process_count: worker_per_process_count.sub('0', ' '),
    load_type: load_type,
    metrics: json["metrics"]
  )

  grouped_servers[name] << result
end

load_type = grouped_servers.values.first.first.load_type
puts "Benchmark summary"
puts "  Load type: #{load_type}"
puts "  revision: #{`git rev-parse HEAD`.strip}"
puts "  ruby version: #{RUBY_VERSION}#{RubyVM::YJIT.enabled? ? '+yjit' : ''}"
puts

grouped_servers.each do |name, results|
  puts "  Server: #{name}"
  puts(" " * 20 + "   rps   avg   med   p90   p95   min   max")

  results.each do |result|
    format(result)
  end
  puts
end
