r = Ractor.new(name: "test-name")do
  puts "In Ractor: #{Ractor.current}"
end

r.name
