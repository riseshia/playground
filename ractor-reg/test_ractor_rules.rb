puts "=== Ruby Ractor Sharing Rules ==="
puts "Ruby version: #{RUBY_VERSION}"
puts

# Test what can be shared
tests = {
  "Integer" => 42,
  "String (frozen)" => "hello".freeze,
  "String (not frozen)" => "hello",
  "Symbol" => :hello,
  "Array (frozen, shareable content)" => [1, 2, 3].freeze,
  "Hash (frozen, shareable content)" => {a: 1}.freeze,
  "Ractor" => Ractor.new { Ractor.receive },
  "Class" => String,
  "Module" => Enumerable,
}

tests.each do |name, obj|
  shareable = Ractor.shareable?(obj)
  frozen = obj.frozen?
  puts "#{name.ljust(35)} shareable: #{shareable.to_s.ljust(5)} frozen: #{frozen}"
end

puts
puts "=== Testing move semantics ==="
puts

# Test if object is moved or copied
class Counter
  attr_reader :value

  def initialize
    @value = 0
  end

  def increment
    @value += 1
  end
end

counter = Counter.new
counter.increment
puts "Counter before Ractor.new: #{counter.value}"

begin
  # Try to pass counter to a Ractor
  r = Ractor.new(counter) do |c|
    c.increment
    c.increment
    c.value
  end

  result = r.take
  puts "Counter inside Ractor: #{result}"

  # Can we still access the original counter?
  begin
    counter.increment
    puts "Counter after Ractor (in main): #{counter.value}"
    puts "→ Object was COPIED (both are accessible)"
  rescue => e
    puts "→ Object was MOVED (original not accessible): #{e.message}"
  end
rescue => e
  puts "Cannot pass counter: #{e.class} - #{e.message}"
end
