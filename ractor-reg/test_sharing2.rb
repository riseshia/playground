require_relative 'ractor_registry'

puts "=== Testing if Registry is Shared or Copied ==="
puts

registry = RactorRegistry.new

# Register a worker in main Ractor
worker1 = Ractor.new do
  loop do
    msg = Ractor.receive
    break if msg == :stop
    Ractor.yield("Worker1 response")
  end
end

registry.register(:worker1, worker1)
puts "Main Ractor registered: #{registry.list_all.inspect}"
puts "Main Ractor count: #{registry.count}"
puts

# Try to register from another Ractor
r = Ractor.new(registry) do |reg|
  worker2 = Ractor.new do
    loop do
      msg = Ractor.receive
      break if msg == :stop
      Ractor.yield("Worker2 response")
    end
  end

  reg.register(:worker2, worker2)

  # What does this Ractor see?
  {
    list: reg.list_all,
    count: reg.count
  }
end

result = r.take
puts "Inside Ractor sees: #{result.inspect}"
puts

# What does main Ractor see now?
puts "Main Ractor now sees: #{registry.list_all.inspect}"
puts "Main Ractor count: #{registry.count}"
puts

# Can main Ractor lookup worker2?
found = registry.lookup(:worker2)
if found
  puts "✓ Main Ractor CAN access :worker2 (SHARED instance)"
  found.send(:ping)
  puts "  Response: #{found.take}"
else
  puts "✗ Main Ractor CANNOT access :worker2 (COPIED instance)"
end

# Cleanup
worker1.send(:stop)
found&.send(:stop)
registry.stop
