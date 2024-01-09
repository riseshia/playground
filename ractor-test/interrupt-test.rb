trap(:INT) do
  puts "SIGINT"
  exit
end

trap(:TERM) do
  puts "SIGTERM"
  exit
end

r = Ractor.new do
  loop do
    sleep 1
  end
end

Ractor.select(r)
