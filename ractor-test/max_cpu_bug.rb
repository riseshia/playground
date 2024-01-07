$stdout.sync = true
$stderr.sync = true

File.write("process.pid", Process.pid)
Ractor.new { 1 }

Thread.new { puts "hello from thread" }
# Thread.new { puts "hello from thread" }
# Thread.new { puts "hello from thread" }
# Ractor.new { puts 1 }
# Ractor.new { puts 1 }
# Ractor.new { puts 1 }
puts "------------" * 10
