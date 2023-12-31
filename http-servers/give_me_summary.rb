require 'json'

def format(filename, metrics)
  name, process_count, worker_per_process_count, load_type = filename.split('-')
  if name == 'multi_threaded'
    process_count = 1
  elsif name == 'single_threaded'
    process_count = 1
    worker_per_process_count = 1
  end
  formatted_name = "[#{load_type}] #{name} (#{process_count} cpu, #{worker_per_process_count} workers)"

  rps = metrics["iterations"]["rate"]
  iteration_duration = metrics["iteration_duration"]
  col = []
  col << formatted_name.ljust(50)
  col << "rps: #{rps.to_i.to_s.rjust(4)}"
  col << "avg: #{iteration_duration['avg'].to_i.to_s.rjust(4)}"
  col << "med: #{iteration_duration['med'].to_i.to_s.rjust(4)}"
  col << "p90: #{iteration_duration['p(90)'].to_i.to_s.rjust(4)}"
  col << "p95: #{iteration_duration['p(95)'].to_i.to_s.rjust(4)}"
  col << "min: #{iteration_duration['min'].to_i.to_s.rjust(4)}"
  col << "max: #{iteration_duration['max'].to_i.to_s.rjust(4)}"

  puts col.join(' ')
end

Dir["reports/*.json"].each do |file|
  json = JSON.parse(File.read(file))
  filename = file.split('/').last.split('.').first

  format(filename, json["metrics"])
end
