require "socket"

# client
socket = TCPSocket.open("127.0.0.1", 12345)
socket.send("HELLO", 0)
socket.close

# server

