# frozen_string_literal: true

require 'socket'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'

class SingleThreadedServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze

  attr_accessor :app

  # app: Rack app
  def initialize(app)
    self.app = app
  end

  def start
    socket = TCPServer.new(HOST, PORT)

    loop do
      conn, _addr_info = socket.accept
      request = RequestParser.call(conn)
      status, headers, body = app.call(request)
      HttpResponder.call(conn, status, headers, body)
    rescue => e
      puts e.message
    ensure
      conn&.close
    end
  end
end
