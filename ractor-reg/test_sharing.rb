require_relative 'ractor_registry'

puts "=== Testing Object Sharing in Ractors ==="
puts

# Test 1: Can we share a normal object?
puts "Test 1: Sharing a normal object"
class NormalObject
  def initialize
    @data = "hello"
  end

  def greet
    @data
  end
end

normal = NormalObject.new
begin
  r = Ractor.new(normal) do |obj|
    obj.greet
  end
  puts "✓ Normal object shared: #{r.take}"
rescue => e
  puts "✗ Normal object cannot be shared: #{e.class} - #{e.message}"
end
puts

# Test 2: Can we share RactorRegistry?
puts "Test 2: Sharing RactorRegistry instance"
registry = RactorRegistry.new

begin
  r = Ractor.new(registry) do |reg|
    worker = Ractor.new do
      loop do
        msg = Ractor.receive
        break if msg == :stop
        Ractor.yield("Response")
      end
    end

    reg.register(:test_worker, worker)
    "Registered from another Ractor"
  end

  result = r.take
  puts "✓ RactorRegistry shared: #{result}"

  # Verify registration worked
  found = registry.lookup(:test_worker)
  if found
    puts "✓ Worker is accessible from main Ractor"
    found.send(:stop)
  end
rescue => e
  puts "✗ RactorRegistry cannot be shared: #{e.class} - #{e.message}"
end
puts

# Test 3: Check if registry is shareable
puts "Test 3: Is RactorRegistry shareable?"
registry2 = RactorRegistry.new
puts "Shareable? #{Ractor.shareable?(registry2)}"
puts "Frozen? #{registry2.frozen?}"
puts "Registry ractor class: #{registry2.instance_variable_get(:@registry_ractor).class}"
puts

registry.stop if registry
registry2.stop if registry2
