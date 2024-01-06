$stdout.sync = true
$stderr.sync = true

File.write("process.pid", Process.pid)
Ractor.new { 1 }
puts "------------" * 10
