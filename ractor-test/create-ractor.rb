r = Ractor.new do
  puts "In Ractor: #{Ractor.current}"
end

# p r.take
p 111
