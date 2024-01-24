def handle(data)
  Ractor.new(data) do |data|
    puts data
  end
end

100_000.times do |i|
  handle(i)
end

sleep 10
