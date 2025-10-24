# frozen_string_literal: true

require_relative 'ractor_registry'

puts "=== RactorRegistry Example ==="
puts

# Create a registry
registry = RactorRegistry.new

# Create some worker Ractors

# 1. Calculator worker
calculator = Ractor.new do
  loop do
    operation, *args = Ractor.receive
    result = case operation
             when :add
               args.sum
             when :multiply
               args.reduce(1, :*)
             when :stop
               break
             else
               "Unknown operation"
             end
    Ractor.yield(result)
  end
end

# 2. Logger worker
logger = Ractor.new do
  loop do
    message = Ractor.receive
    break if message == :stop
    puts "[Logger #{Time.now}] #{message}"
  end
end

# 3. Counter worker
counter = Ractor.new do
  count = 0
  loop do
    cmd = Ractor.receive
    case cmd
    when :increment
      count += 1
      Ractor.yield(count)
    when :get
      Ractor.yield(count)
    when :stop
      break
    end
  end
end

puts "Created 3 worker Ractors"
puts

# Register workers
puts "--- Registering workers ---"
registry.register(:calculator, calculator)
puts "✓ Registered :calculator"

registry.register(:logger, logger)
puts "✓ Registered :logger"

registry.register(:counter, counter)
puts "✓ Registered :counter"
puts

# Show registry status
puts "--- Registry Status ---"
puts "Total registered: #{registry.count}"
puts "Registered names: #{registry.list_all.inspect}"
puts

# Test lookups and usage
puts "--- Using registered Ractors ---"

# Use calculator
if calc = registry.lookup(:calculator)
  calc.send([:add, 1, 2, 3, 4, 5])
  result = calc.take
  puts "Calculator: 1+2+3+4+5 = #{result}"

  calc.send([:multiply, 2, 3, 4])
  result = calc.take
  puts "Calculator: 2*3*4 = #{result}"
end

# Use logger
if log = registry.lookup(:logger)
  log.send("Application started")
  log.send("Processing data...")
  sleep 0.1 # Give logger time to process
end

# Use counter
if cnt = registry.lookup(:counter)
  cnt.send(:increment)
  puts "Counter: #{cnt.take}"

  cnt.send(:increment)
  puts "Counter: #{cnt.take}"

  cnt.send(:get)
  puts "Counter: #{cnt.take}"
end
puts

# Test lookup of non-existent worker
puts "--- Testing non-existent lookup ---"
result = registry.lookup(:nonexistent)
puts "Lookup :nonexistent = #{result.inspect}"
puts

# Test duplicate registration (should fail)
puts "--- Testing duplicate registration ---"
begin
  dummy = Ractor.new { loop { Ractor.receive } }
  registry.register(:calculator, dummy)
  puts "ERROR: Should have raised AlreadyRegisteredError"
rescue RactorRegistry::AlreadyRegisteredError => e
  puts "✓ Correctly raised error: #{e.message}"
end
puts

# Test unregister
puts "--- Testing unregister ---"
puts "Before unregister: #{registry.list_all.inspect}"
success = registry.unregister(:logger)
puts "Unregister :logger = #{success}"
puts "After unregister: #{registry.list_all.inspect}"

# Verify logger is no longer accessible
result = registry.lookup(:logger)
puts "Lookup :logger after unregister = #{result.inspect}"
puts

# Test lookup! (raising version)
puts "--- Testing lookup! (raising version) ---"
begin
  registry.lookup!(:nonexistent)
  puts "ERROR: Should have raised NotFoundError"
rescue RactorRegistry::NotFoundError => e
  puts "✓ Correctly raised error: #{e.message}"
end

# Successful lookup!
found = registry.lookup!(:calculator)
puts "✓ lookup!(:calculator) succeeded: #{found.class}"
puts

# Cleanup
puts "--- Cleanup ---"
calculator.send(:stop)
logger.send(:stop)
counter.send(:stop)
puts "Stopped all workers"

registry.stop
puts "Stopped registry"
puts

puts "=== Example completed successfully ==="
