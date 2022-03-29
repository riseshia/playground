require "socket"

# send

@udp = UDPSocket.open

@dst_addr = "18.180.200.17"
@dst_port = 12345
@msg = "HELLO"

# 引数が2つの場合
def send_with_2args
  @udp.connect(@dst_addr, @dst_port)
  @udp.send(@msg, 0)
end

# 引数が3つの場合
def send_with_3args
  sockaddr = Socket.pack_sockaddr_in(@dst_port, @dst_addr)
  @udp.send(@msg, 0, sockaddr)
end

# 引数が4つの場合
def send_with_4args
  @udp.send(@msg, 0, @dst_addr, @dst_port)
end

# send_with_2args
# send_with_3args
send_with_4args
@udp.close

#########################
# recv

udps = UDPSocket.open
udps.bind("127.0.0.1", 12345)

begin
  loop do
    pp udps.recv(5) # => HELLO
  end
rescue Interrupt
  puts "Exit"
  udps.close
end
