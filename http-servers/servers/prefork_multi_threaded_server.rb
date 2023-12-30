# frozen_string_literal: true

require 'socket'
require_relative './thread_pool'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'

class PreforkMultiThreadedServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  WORKER_PER_PROCESS_COUNT = ENV.fetch('WORKER_PER_PROCESS_COUNT', 4).to_i
  PROCESS_COUNT = ENV.fetch('PROCESS_COUNT', 2).to_i

  attr_accessor :app

  # app: Rack app
  def initialize(app)
    self.app = app
  end

  def start
    write_pid

    socket = TCPServer.new(HOST, PORT)

    workers = []

    PROCESS_COUNT.times do
      workers << fork do
        pool = ThreadPool.new(size: WORKER_PER_PROCESS_COUNT)
        loop do
          conn, _addr_info = socket.accept
          # execute the request in one of the threads
          pool.perform do
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
    end

    trap(:TERM) do
      workers.each { |worker| Process.kill(:TERM, worker) }
    end
    trap(:INT) do
      workers.each { |worker| Process.kill(:TERM, worker) }
    end
    workers.each { |worker| Process.waitpid(worker) }
  end

  private def write_pid
    File.write('tmp/server.pid', Process.pid)
  end
end
