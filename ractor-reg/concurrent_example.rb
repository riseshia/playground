# frozen_string_literal: true

require_relative 'ractor_registry'

puts "=== RactorRegistry Concurrent Access Example ==="
puts

registry = RactorRegistry.new

# Create worker pool
puts "--- Creating Worker Pool ---"
workers = 5.times.map do |i|
  worker = Ractor.new(i) do |id|
    loop do
      msg = Ractor.receive
      case msg
      when :ping
        Ractor.yield("Pong from worker #{id}")
      when :work
        sleep(rand * 0.1) # Simulate work
        Ractor.yield("Worker #{id} completed task")
      when :stop
        break
      end
    end
  end

  name = "worker_#{i}".to_sym
  registry.register(name, worker)
  puts "✓ Registered #{name}"
  worker
end
puts

# Create multiple client Ractors that access the registry concurrently
puts "--- Testing Concurrent Access ---"
clients = 3.times.map do |i|
  # Share registry Ractor reference (Ractors can be shared)
  Ractor.new(registry, i) do |reg, client_id|
    results = []

    # Each client randomly accesses different workers
    5.times do
      worker_id = rand(5)
      worker_name = "worker_#{worker_id}".to_sym

      # Lookup worker from registry
      worker = reg.lookup(worker_name)

      if worker
        worker.send(:ping)
        response = worker.take
        results << "Client #{client_id}: #{response}"
      end

      sleep(rand * 0.05) # Simulate some delay
    end

    results
  end
end

# Collect results from all clients
clients.each_with_index do |client, i|
  results = client.take
  puts "\nClient #{i} results:"
  results.each { |r| puts "  #{r}" }
end
puts

# Test concurrent worker execution
puts "--- Testing Concurrent Worker Execution ---"
tasks = 5.times.map do |i|
  Ractor.new(registry, i) do |reg, task_id|
    worker = reg.lookup("worker_#{task_id}".to_sym)
    worker.send(:work)
    result = worker.take
    "Task #{task_id}: #{result}"
  end
end

# Wait for all tasks
tasks.each do |task|
  puts task.take
end
puts

# Verify registry state
puts "--- Registry State ---"
puts "Total workers: #{registry.count}"
puts "Registered workers: #{registry.list_all.inspect}"
puts

# Test registering from another Ractor
puts "--- Testing Registration from Another Ractor ---"
registration_ractor = Ractor.new(registry) do |reg|
  new_worker = Ractor.new do
    loop do
      msg = Ractor.receive
      break if msg == :stop
      Ractor.yield("Dynamic worker response")
    end
  end

  reg.register(:dynamic_worker, new_worker)
  "Successfully registered :dynamic_worker from another Ractor"
end

puts registration_ractor.take
puts "Registry now has #{registry.count} workers"
puts

# Use the dynamically registered worker
puts "--- Using Dynamically Registered Worker ---"
dynamic = registry.lookup(:dynamic_worker)
if dynamic
  dynamic.send(:ping)
  puts dynamic.take
end
puts

# Cleanup
puts "--- Cleanup ---"
registry.list_all.each do |name|
  worker = registry.lookup(name)
  worker&.send(:stop)
  puts "✓ Stopped #{name}"
end

registry.stop
puts "✓ Stopped registry"
puts

puts "=== Concurrent example completed successfully ==="
