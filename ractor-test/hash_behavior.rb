h = Hash.new { |h, k| h[k] = [] }

h[:a] = 1
p h

puts "Ractor.shareable? #{Ractor.shareable?(h)}"
# <internal:ractor>:831:in `make_shareable': Proc's self is not shareable: #<Proc:0x00007fc2a7dc7258 hash_behavior.rb:1> (Ractor::IsolationError)
#         from hash_behavior.rb:7:in `<main>'
# Ractor.make_shareable(h.dup)

new_h = Hash.new.tap do |new_h|
  h.each do |k, v|
    h[k] = v
  end
end

Ractor.make_shareable(new_h)
