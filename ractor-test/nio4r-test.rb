require 'nio'

selector = NIO::Selector.new

server = TCPServer.new('localhost', 1234)

selector.register(server, :r)

r = Ractor.new do
  msg = Ractor.receive
  puts "message"
  p msg
end

selector.select do |monitor|
  case monitor.io
  when TCPServer
    if monitor.readable?
      # This means our TCPServer has new connections!
      client = monitor.io.accept_nonblock
      puts "accepted"
      r.send(client)
      r.take
    end
  end
end
