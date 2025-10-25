# frozen_string_literal: true

require_relative '../lib/ractor_port'

puts "=== Basic Ractor::Port Usage ==="
puts

# Example 1: Simple send and receive
puts "Example 1: Basic send and receive"
port = Ractor::Port.new

sender = Ractor.new(port) do |p|
  p << "Hello from another Ractor!"
end

message = port.receive
puts "Received: #{message}"
sender.take
puts

# Example 2: Multiple messages
puts "Example 2: Multiple messages"
port2 = Ractor::Port.new

Ractor.new(port2) do |p|
  5.times do |i|
    p << "Message #{i + 1}"
    sleep 0.1
  end
end

5.times do
  puts "Received: #{port2.receive}"
end
puts

# Example 3: Multiple senders
puts "Example 3: Multiple senders"
port3 = Ractor::Port.new

workers = 3.times.map do |i|
  Ractor.new(port3, i) do |p, worker_id|
    3.times do |j|
      p << "Worker #{worker_id}, Message #{j + 1}"
      sleep rand(0.1..0.3)
    end
  end
end

# Receive all messages
9.times do
  puts "Received: #{port3.receive}"
end

workers.each(&:take)
puts

# Example 4: Closing a port
puts "Example 4: Closing a port"
port4 = Ractor::Port.new

Ractor.new(port4) do |p|
  p << "Message 1"
  p << "Message 2"
end

sleep 0.1
puts "Received: #{port4.receive}"
puts "Received: #{port4.receive}"

port4.close
puts "Port closed: #{port4.closed?}"

begin
  port4.send("This will fail")
rescue Ractor::Port::ClosedError => e
  puts "Error when sending to closed port: #{e.message}"
end

begin
  port4.receive
rescue Ractor::Port::ClosedError => e
  puts "Error when receiving from closed empty port: #{e.message}"
end
puts

# Example 5: Permission control
puts "Example 5: Only owner can receive"
port5 = Ractor::Port.new

receiver = Ractor.new(port5) do |p|
  begin
    p.receive  # This should fail
    "Should not reach here"
  rescue Ractor::Port::PermissionError
    "Only the creator Ractor can receive from or close this port"
  end
end

result = receiver.take
puts "Error from non-owner: #{result}"
puts

# Example 6: Producer-Consumer pattern
puts "Example 6: Producer-Consumer pattern"
port6 = Ractor::Port.new

# Producer
producer = Ractor.new(port6) do |p|
  10.times do |i|
    p << i * i  # Send squares
    sleep 0.05
  end
  puts "Producer finished"
end

# Consumer (main Ractor)
sum = 0
10.times do
  value = port6.receive
  sum += value
  puts "Processing: #{value}"
end

producer.take
puts "Total sum: #{sum}"
puts

puts "=== All examples completed successfully! ==="
