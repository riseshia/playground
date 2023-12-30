# frozen_string_literal: true

require 'socket'
require_relative './thread_pool'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'

class MultiThreadedServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  WORKERS_COUNT = ENV.fetch('WORKERS', 4).to_i

  attr_accessor :app

  # app: Rack app
  def initialize(app)
    self.app = app
  end

  def start
    write_pid

    pool = ThreadPool.new(size: WORKERS_COUNT)
    socket = TCPServer.new(HOST, PORT)

    loop do
      conn, _addr_info = socket.accept
      # execute the request in one of the threads
      pool.perform do
        begin
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
  ensure
    pool&.shutdown
  end

  private def write_pid
    File.write('tmp/server.pid', Process.pid)
  end
end
