$stdout.sync = true
$stderr.sync = true

def tarai(x, y, z)
  if x <= y
    y
  else
    tarai(tarai(x-1, y, z), tarai(y-1, z, x), tarai(z-1, x, y))
  end
end

def computation
  1000.times do |i|
    23_467**2436
    # Math.sqrt(VAL) * i / 0.2
  end
end

File.write("process.pid", Process.pid)
cpu_num = ENV["RUBY_MAX_CPU"].to_i
ractor_num = 64 * 8

arr = []
(cpu_num * ractor_num).times do
  puts "generate ractor"
  # cpu=4 usage 300
  # arr << Ractor.new { 100.times { tarai(10, 5, 0) } }
  # cpu=4 usage 300
  # arr << Ractor.new { 100.times { tarai(10, 5, 0); File.read("./process.pid") } }
  # cpu=4 usage 280
  arr << Ractor.new { computation }
  # arr << Thread.new { tarai(14, 7, 0) }
end

arr.each(&:take)

puts "done"
