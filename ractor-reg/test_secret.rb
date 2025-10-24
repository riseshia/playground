require_relative 'ractor_registry'

puts "=== The Secret of RactorRegistry Sharing ==="
puts

registry = RactorRegistry.new

# Get the internal registry ractor
main_internal = registry.instance_variable_get(:@registry_ractor)
puts "Main Ractor's @registry_ractor object_id: #{main_internal.object_id}"
puts

# Pass registry to another Ractor
r = Ractor.new(registry) do |reg|
  # Get the internal registry ractor inside this Ractor
  internal = reg.instance_variable_get(:@registry_ractor)

  {
    registry_instance_id: reg.object_id,
    internal_ractor_id: internal.object_id,
    internal_ractor_shareable: Ractor.shareable?(internal)
  }
end

result = r.take

puts "Inside another Ractor:"
puts "  registry instance object_id: #{result[:registry_instance_id]}"
puts "  @registry_ractor object_id:  #{result[:internal_ractor_id]}"
puts "  @registry_ractor shareable?:  #{result[:internal_ractor_shareable]}"
puts

puts "Main Ractor:"
puts "  registry instance object_id: #{registry.object_id}"
puts "  @registry_ractor object_id:  #{main_internal.object_id}"
puts

if main_internal.object_id == result[:internal_ractor_id]
  puts "✓ SAME @registry_ractor object!"
  puts "  → Even though RactorRegistry instance is COPIED,"
  puts "  → the internal Ractor object is SHARED (because Ractor is shareable)"
else
  puts "✗ Different @registry_ractor objects"
end

registry.stop
