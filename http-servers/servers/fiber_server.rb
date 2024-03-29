# frozen_string_literal: true

require 'socket'
require 'libev_scheduler'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'

class FiberServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze

  attr_accessor :app

  # app: Rack app
  def initialize(app)
    self.app = app
  end

  def start
    write_pid
    # Fibers are not going to work without a scheduler.
    # A scheduler is on for a current thread.
    # Some scheduler choices:
    # evt: https://github.com/dsh0416/evt
    # libev_scheduler: https://github.com/digital-fabric/libev_scheduler
    # Async: https://github.com/socketry/async
    Fiber.set_scheduler(Libev::Scheduler.new)

    Fiber.schedule do
      server = TCPServer.new(HOST, PORT)

      loop do
        conn, _addr_info = server.accept
        # ideally we need to limit number of fibers
        # via a thread pool, as accepting infinite number
        # of request is a bad idea:
        # we can run out of memory or other resources,
        # there are diminishing returns to too many fibers,
        # without backpressure to however is sending the requests it's hard
        # to properly load balance and queue requests
        Fiber.schedule do
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

  private def write_pid
    File.write('tmp/server.pid', Process.pid)
  end
end
