# frozen_string_literal: true

require 'stringio'

require_relative 'thread_pool'
require_relative 'const'
require_relative 'log_writer'
require_relative 'events'
require_relative 'null_io'
require_relative 'reactor'
require_relative 'client'
require_relative 'binder'
require_relative 'util'
require_relative 'request'

require 'socket'
require 'io/wait' unless Puma::HAS_NATIVE_IO_WAIT

module Puma
  class Server
    include Puma::Const
    include Request

    attr_reader :thread
    attr_reader :log_writer
    attr_reader :events
    attr_reader :min_threads, :max_threads  # for #stats
    attr_reader :requests_count             # @version 5.0.0
    attr_reader :idle_timeout_reached

    attr_reader :auto_trim_time, :early_hints, :first_data_timeout,
      :leak_stack_on_error,
      :persistent_timeout, :reaping_time

    attr_accessor :app
    attr_accessor :binder

    THREAD_LOCAL_KEY = :puma_server

    def initialize(app, events = nil, options = {})
      @app = app
      @events = events || Events.new

      @check, @notify = nil
      @status = :stop

      @thread = nil
      @thread_pool = nil

      @options = if options.is_a?(UserFileDefaultOptions)
        options
      else
        UserFileDefaultOptions.new(options, Configuration::DEFAULTS)
      end

      @log_writer                = @options.fetch :log_writer, LogWriter.stdio
      @early_hints               = @options[:early_hints]
      @first_data_timeout        = @options[:first_data_timeout]
      @persistent_timeout        = @options[:persistent_timeout]
      @idle_timeout              = @options[:idle_timeout]
      @min_threads               = @options[:min_threads]
      @max_threads               = @options[:max_threads]
      @queue_requests            = @options[:queue_requests]
      @max_fast_inline           = @options[:max_fast_inline]
      @io_selector_backend       = @options[:io_selector_backend]
      @http_content_length_limit = @options[:http_content_length_limit]

      @supported_http_methods =
        if @options[:supported_http_methods] == :any
          :any
        else
          if (ary = @options[:supported_http_methods])
            ary
          else
            SUPPORTED_HTTP_METHODS
          end.sort.product([nil]).to_h.freeze
        end

      temp = !!(@options[:environment] =~ /\A(development|test)\z/)
      @leak_stack_on_error = @options[:environment] ? temp : true

      @binder = Binder.new(log_writer)

      ENV['RACK_ENV'] ||= "development"

      @mode = :http

      @precheck_closing = true

      @requests_count = 0

      @idle_timeout_reached = false
    end

    def inherit_binder(bind)
      @binder = bind
    end

    class << self
      def current
        Thread.current[THREAD_LOCAL_KEY]
      end

      def tcp_cork_supported?
        Socket.const_defined?(:TCP_CORK) && Socket.const_defined?(:IPPROTO_TCP)
      end

      def closed_socket_supported?
        Socket.const_defined?(:TCP_INFO) && Socket.const_defined?(:IPPROTO_TCP)
      end
      private :tcp_cork_supported?
      private :closed_socket_supported?
    end

    if tcp_cork_supported?
      def cork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 1) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
        end
      end

      def uncork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 0) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
        end
      end
    else
      def cork_socket(socket)
      end

      def uncork_socket(socket)
      end
    end

    if closed_socket_supported?
      UNPACK_TCP_STATE_FROM_TCP_INFO = "C".freeze

      def closed_socket?(socket)
        skt = socket.to_io
        return false unless skt.kind_of?(TCPSocket) && @precheck_closing

        begin
          tcp_info = skt.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO)
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          @precheck_closing = false
          false
        else
          state = tcp_info.unpack(UNPACK_TCP_STATE_FROM_TCP_INFO)[0]
          (state >= 6 && state <= 9) || state == 11
        end
      end
    else
      def closed_socket?(socket)
        false
      end
    end

    def backlog
      @thread_pool&.backlog
    end

    def running
      @thread_pool&.spawned
    end

    def pool_capacity
      @thread_pool&.pool_capacity
    end

    def run(background=true, thread_name: 'srv')
      BasicSocket.do_not_reverse_lookup = true

      @events.fire :state, :booting

      @status = :run

      @thread_pool = ThreadPool.new(thread_name, @options) { |client| process_client client }

      if @queue_requests
        @reactor = Reactor.new(@io_selector_backend) { |c| reactor_wakeup c }
        @reactor.run
      end

      @thread_pool.auto_reap! if @options[:reaping_time]
      @thread_pool.auto_trim! if @options[:auto_trim_time]

      @check, @notify = Puma::Util.pipe unless @notify

      @events.fire :state, :running

      if background
        @thread = Thread.new do
          Puma.set_thread_name thread_name
          handle_servers
        end
        return @thread
      else
        handle_servers
      end
    end

    def reactor_wakeup(client)
      shutdown = !@queue_requests
      if client.try_to_finish || (shutdown && !client.can_close?)
        @thread_pool << client
      elsif shutdown || client.timeout == 0
        client.timeout!
      else
        client.set_timeout(@first_data_timeout)
        false
      end
    rescue StandardError => e
      client_error(e, client)
      client.close
      true
    end

    def handle_servers
      begin
        check = @check
        sockets = [check] + @binder.ios
        pool = @thread_pool
        queue_requests = @queue_requests
        drain = @options[:drain_on_shutdown] ? 0 : nil

        addr_send_name, addr_value = case @options[:remote_address]
        when :value
          [:peerip=, @options[:remote_address_value]]
        when :header
          [:remote_addr_header=, @options[:remote_address_header]]
        when :proxy_protocol
          [:expect_proxy_proto=, @options[:remote_address_proxy_protocol]]
        else
          [nil, nil]
        end

        while @status == :run || (drain && shutting_down?)
          begin
            ios = IO.select sockets, nil, nil, (shutting_down? ? 0 : @idle_timeout)
            unless ios
              unless shutting_down?
                @idle_timeout_reached = true
                @status = :stop
              end

              break
            end

            ios.first.each do |sock|
              if sock == check
                break if handle_check
              else
                pool.wait_until_not_full
                pool.wait_for_less_busy_worker(@options[:wait_for_less_busy_worker])

                io = begin
                  sock.accept_nonblock
                rescue IO::WaitReadable
                  next
                end
                drain += 1 if shutting_down?
                pool << Client.new(io, @binder.env(sock)).tap { |c|
                  c.listener = sock
                  c.http_content_length_limit = @http_content_length_limit
                  c.send(addr_send_name, addr_value) if addr_value
                }
              end
            end
          rescue IOError, Errno::EBADF
            # In the case that any of the sockets are unexpectedly close.
            raise
          rescue StandardError => e
            @log_writer.unknown_error e, nil, "Listen loop"
          end
        end

        @log_writer.debug "Drained #{drain} additional connections." if drain
        @events.fire :state, @status

        if queue_requests
          @queue_requests = false
          @reactor.shutdown
        end

        graceful_shutdown if @status == :stop || @status == :restart
      rescue Exception => e
        @log_writer.unknown_error e, nil, "Exception handling servers"
      ensure
        [@check, @notify].each do |io|
          begin
            io.close unless io.closed?
          rescue Errno::EBADF
          end
        end
        @notify = nil
        @check = nil
      end

      @events.fire :state, :done
    end

    def handle_check
      cmd = @check.read(1)

      case cmd
      when STOP_COMMAND
        @status = :stop
        return true
      when HALT_COMMAND
        @status = :halt
        return true
      when RESTART_COMMAND
        @status = :restart
        return true
      end

      false
    end

    def process_client(client)
      Thread.current[THREAD_LOCAL_KEY] = self

      clean_thread_locals = @options[:clean_thread_locals]
      close_socket = true

      requests = 0

      begin
        if @queue_requests &&
          !client.eagerly_finish

          client.set_timeout(@first_data_timeout)
          if @reactor.add client
            close_socket = false
            return false
          end
        end

        with_force_shutdown(client) do
          client.finish(@first_data_timeout)
        end

        while true
          @requests_count += 1
          case handle_request(client, requests + 1)
          when false
            break
          when :async
            close_socket = false
            break
          when true
            ThreadPool.clean_thread_locals if clean_thread_locals

            requests += 1

            fast_check = @status == :run

            fast_check = false if requests >= @max_fast_inline &&
              @thread_pool.backlog > 0

            next_request_ready = with_force_shutdown(client) do
              client.reset(fast_check)
            end

            unless next_request_ready
              break unless @queue_requests
              client.set_timeout @persistent_timeout
              if @reactor.add client
                close_socket = false
                break
              end
            end
          end
        end
        true
      rescue StandardError => e
        client_error(e, client, requests)
        requests > 0
      ensure
        client.io_buffer.reset

        begin
          client.close if close_socket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          # Already closed
        rescue StandardError => e
          @log_writer.unknown_error e, nil, "Client"
        end
      end
    end

    def with_force_shutdown(client, &block)
      @thread_pool.with_force_shutdown(&block)
    rescue ThreadPool::ForceShutdown
      client.timeout!
    end

    def client_error(e, client, requests = 1)
      return if [ConnectionError, EOFError].include?(e.class)

      case e
      when MiniSSL::SSLError
        lowlevel_error(e, client.env)
        @log_writer.ssl_error e, client.io
      when HttpParserError
        response_to_error(client, requests, e, 400)
        @log_writer.parse_error e, client
      when HttpParserError501
        response_to_error(client, requests, e, 501)
        @log_writer.parse_error e, client
      else
        response_to_error(client, requests, e, 500)
        @log_writer.unknown_error e, nil, "Read"
      end
    end

    def lowlevel_error(e, env, status=500)
      if handler = @options[:lowlevel_error_handler]
        if handler.arity == 1
          return handler.call(e)
        elsif handler.arity == 2
          return handler.call(e, env)
        else
          return handler.call(e, env, status)
        end
      end

      if @leak_stack_on_error
        backtrace = e.backtrace.nil? ? '<no backtrace available>' : e.backtrace.join("\n")
        [status, {}, ["Puma caught this error: #{e.message} (#{e.class})\n#{backtrace}"]]
      else
        [status, {}, [""]]
      end
    end

    def response_to_error(client, requests, err, status_code)
      status, headers, res_body = lowlevel_error(err, client.env, status_code)
      prepare_response(status, headers, res_body, requests, client)
      client.write_error(status_code)
    end
    private :response_to_error

    def graceful_shutdown
      if @options[:shutdown_debug]
        threads = Thread.list
        total = threads.size

        pid = Process.pid

        $stdout.syswrite "#{pid}: === Begin thread backtrace dump ===\n"

        threads.each_with_index do |t,i|
          $stdout.syswrite "#{pid}: Thread #{i+1}/#{total}: #{t.inspect}\n"
          $stdout.syswrite "#{pid}: #{t.backtrace.join("\n#{pid}: ")}\n\n"
        end
        $stdout.syswrite "#{pid}: === End thread backtrace dump ===\n"
      end

      if @status != :restart
        @binder.close
      end

      if @thread_pool
        if timeout = @options[:force_shutdown_after]
          @thread_pool.shutdown timeout.to_f
        else
          @thread_pool.shutdown
        end
      end
    end

    def notify_safely(message)
      @notify << message
    rescue IOError, NoMethodError, Errno::EPIPE, Errno::EBADF
      Puma::Util.purge_interrupt_queue
    rescue RuntimeError => e
      if e.message.include?('IOError')
        Puma::Util.purge_interrupt_queue
      else
        raise e
      end
    end
    private :notify_safely

    def stop(sync=false)
      notify_safely(STOP_COMMAND)
      @thread.join if @thread && sync
    end

    def halt(sync=false)
      notify_safely(HALT_COMMAND)
      @thread.join if @thread && sync
    end

    def begin_restart(sync=false)
      notify_safely(RESTART_COMMAND)
      @thread.join if @thread && sync
    end

    def shutting_down?
      @status == :stop || @status == :restart
    end

    STAT_METHODS = [:backlog, :running, :pool_capacity, :max_threads, :requests_count].freeze

    def stats
      STAT_METHODS.map {|name| [name, send(name) || 0]}.to_h
    end

    def add_tcp_listener(host, port, optimize_for_latency = true, backlog = 1024)
      @binder.add_tcp_listener host, port, optimize_for_latency, backlog
    end

    def add_ssl_listener(host, port, ctx, optimize_for_latency = true,
                         backlog = 1024)
      @binder.add_ssl_listener host, port, ctx, optimize_for_latency, backlog
    end

    def add_unix_listener(path, umask = nil, mode = nil, backlog = 1024)
      @binder.add_unix_listener path, umask, mode, backlog
    end

    def connected_ports
      @binder.connected_ports
    end
  end
end
