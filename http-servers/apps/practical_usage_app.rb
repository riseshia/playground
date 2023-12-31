# frozen_string_literal: true

require 'socket'

class PracticalUsageApp
  CHARS = ('a'..'z').map(&:freeze).freeze

  def call(_env)
    res_body = ""
    5.times do |_i|
      # this is SLOWER with ractors
      # 500.downto(1) do |j|
      #   Math.sqrt(j) * i / 0.2
      # end
      1000.times do |i|
        Math.sqrt(23_467**2436) * i / 0.2
      end

      sleep 0.01

      res_body += fetch_remote_data
      res_body += "\n"
      partial = 1000.times.map { CHARS.sample }.join
      res_body += partial
      res_body += "\n"
    end

    [200, { "Content-Type" => "text/html" }, [res_body]]
  end

  def fetch_remote_data
    all_data = []

    TCPSocket.open('localhost', 9292) do |socket|
      socket.print "GET / HTTP/1.0\r\n\r\n"

      loop do
        partial_data = socket.read
        break if partial_data.empty?

        all_data << partial_data
      end
    end

    all_data.join
  end
end
