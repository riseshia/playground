# frozen_string_literal: true

module Puma
  module Request # :nodoc:
    BODY_LEN_MAX = 1_024 * 256

    IO_BODY_MAX = 1_024 * 64

    IO_BUFFER_LEN_MAX = 1_024 * 512

    SOCKET_WRITE_ERR_MSG = "Socket timeout writing data"

    CUSTOM_STAT = 'CUSTOM'

    include Puma::Const

    def handle_request(client, requests)
      env = client.env
      io_buffer = client.io_buffer
      socket  = client.io   # io may be a MiniSSL::Socket
      app_body = nil

      return false if closed_socket?(socket)

      if client.http_content_length_limit_exceeded
        return prepare_response(413, {}, ["Payload Too Large"], requests, client)
      end

      normalize_env env, client

      env[PUMA_SOCKET] = socket

      if env[HTTPS_KEY] && socket.peercert
        env[PUMA_PEERCERT] = socket.peercert
      end

      env[HIJACK_P] = true
      env[HIJACK] = client

      env[RACK_INPUT] = client.body
      env[RACK_URL_SCHEME] ||= default_server_port(env) == PORT_443 ? HTTPS : HTTP

      if @early_hints
        env[EARLY_HINTS] = lambda { |headers|
          begin
            unless (str = str_early_hints headers).empty?
              fast_write_str socket, "HTTP/1.1 103 Early Hints\r\n#{str}\r\n"
            end
          rescue ConnectionError => e
            @log_writer.debug_error e
          end
        }
      end

      req_env_post_parse env

      env[RACK_AFTER_REPLY] ||= []

      begin
        if @supported_http_methods == :any || @supported_http_methods.key?(env[REQUEST_METHOD])
          status, headers, app_body = @thread_pool.with_force_shutdown do
            @app.call(env)
          end
        else
          @log_writer.log "Unsupported HTTP method used: #{env[REQUEST_METHOD]}"
          status, headers, app_body = [501, {}, ["#{env[REQUEST_METHOD]} method is not supported"]]
        end

        res_body = app_body

        return :async if client.hijacked

        status = status.to_i

        if status == -1
          unless headers.empty? and res_body == []
            raise "async response must have empty headers and body"
          end

          return :async
        end
      rescue ThreadPool::ForceShutdown => e
        @log_writer.unknown_error e, client, "Rack app"
        @log_writer.log "Detected force shutdown of a thread"

        status, headers, res_body = lowlevel_error(e, env, 503)
      rescue Exception => e
        @log_writer.unknown_error e, client, "Rack app"

        status, headers, res_body = lowlevel_error(e, env, 500)
      end
      prepare_response(status, headers, res_body, requests, client)
    ensure
      io_buffer.reset
      uncork_socket client.io
      app_body.close if app_body.respond_to? :close
      client.tempfile&.unlink
      after_reply = env[RACK_AFTER_REPLY] || []
      begin
        after_reply.each { |o| o.call }
      rescue StandardError => e
        @log_writer.debug_error e
      end unless after_reply.empty?
    end

    def prepare_response(status, headers, res_body, requests, client)
      env = client.env
      socket = client.io
      io_buffer = client.io_buffer

      return false if closed_socket?(socket)

      force_keep_alive = requests < @max_fast_inline ||
        @thread_pool.busy_threads < @max_threads ||
        !client.listener.to_io.wait_readable(0)

      resp_info = str_headers(env, status, headers, res_body, io_buffer, force_keep_alive)

      close_body = false
      response_hijack = nil
      content_length = resp_info[:content_length]
      keep_alive     = resp_info[:keep_alive]

      if res_body.respond_to?(:each) && !resp_info[:response_hijack]
        if !content_length && !resp_info[:transfer_encoding] && status != 204
          if res_body.respond_to?(:to_ary) && (array_body = res_body.to_ary) &&
              array_body.is_a?(Array)
            body = array_body.compact
            content_length = body.sum(&:bytesize)
          elsif res_body.is_a?(File) && res_body.respond_to?(:size)
            body = res_body
            content_length = body.size
          elsif res_body.respond_to?(:to_path) && File.readable?(fn = res_body.to_path)
            body = File.open fn, 'rb'
            content_length = body.size
            close_body = true
          else
            body = res_body
          end
        elsif !res_body.is_a?(::File) && res_body.respond_to?(:to_path) &&
            File.readable?(fn = res_body.to_path)
          body = File.open fn, 'rb'
          content_length = body.size
          close_body = true
        elsif !res_body.is_a?(::File) && res_body.respond_to?(:filename) &&
            res_body.respond_to?(:bytesize) && File.readable?(fn = res_body.filename)
          # Sprockets::Asset
          content_length = res_body.bytesize unless content_length
          if (body_str = res_body.to_hash[:source])
            body = [body_str]
          else                           # avoid each and use a File object
            body = File.open fn, 'rb'
            close_body = true
          end
        else
          body = res_body
        end
      else
        response_hijack = resp_info[:response_hijack] || res_body
      end

      line_ending = LINE_END

      cork_socket socket

      if resp_info[:no_body]
        unless status == 101
          if content_length && status != 204
            io_buffer.append CONTENT_LENGTH_S, content_length.to_s, line_ending
          end

          io_buffer << LINE_END
          fast_write_str socket, io_buffer.read_and_reset
          socket.flush
          return keep_alive
        end
      else
        if content_length
          io_buffer.append CONTENT_LENGTH_S, content_length.to_s, line_ending
          chunked = false
        elsif !response_hijack && resp_info[:allow_chunked]
          io_buffer << TRANSFER_ENCODING_CHUNKED
          chunked = true
        end
      end

      io_buffer << line_ending

      if response_hijack
        fast_write_str socket, io_buffer.read_and_reset
        uncork_socket socket
        response_hijack.call socket
        return :async
      end

      fast_write_response socket, body, io_buffer, chunked, content_length.to_i
      body.close if close_body
      keep_alive
    end

    def default_server_port(env)
      if ['on', HTTPS].include?(env[HTTPS_KEY]) || env[HTTP_X_FORWARDED_PROTO].to_s[0...5] == HTTPS || env[HTTP_X_FORWARDED_SCHEME] == HTTPS || env[HTTP_X_FORWARDED_SSL] == "on"
        PORT_443
      else
        PORT_80
      end
    end

    def fast_write_str(socket, str)
      n = 0
      byte_size = str.bytesize
      while n < byte_size
        begin
          n += socket.write_nonblock(n.zero? ? str : str.byteslice(n..-1))
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          unless socket.wait_writable WRITE_TIMEOUT
            raise ConnectionError, SOCKET_WRITE_ERR_MSG
          end
          retry
        rescue  Errno::EPIPE, SystemCallError, IOError
          raise ConnectionError, SOCKET_WRITE_ERR_MSG
        end
      end
    end

    def fast_write_response(socket, body, io_buffer, chunked, content_length)
      if body.is_a?(::File) && body.respond_to?(:read)
        if chunked  # would this ever happen?
          while chunk = body.read(BODY_LEN_MAX)
            io_buffer.append chunk.bytesize.to_s(16), LINE_END, chunk, LINE_END
          end
          fast_write_str socket, CLOSE_CHUNKED
        else
          if content_length <= IO_BODY_MAX
            io_buffer.write body.read(content_length)
            fast_write_str socket, io_buffer.read_and_reset
          else
            fast_write_str socket, io_buffer.read_and_reset
            IO.copy_stream body, socket
          end
        end
      elsif body.is_a?(::Array) && body.length == 1
        body_first = nil
        body.each { |str| body_first ||= str }

        if body_first.is_a?(::String) && body_first.bytesize < BODY_LEN_MAX
          io_buffer.write body_first
          fast_write_str socket, io_buffer.read_and_reset
        else
          fast_write_str socket, io_buffer.read_and_reset
          fast_write_str socket, body_first
        end
      elsif body.is_a?(::Array)
        if chunked
          body.each do |part|
            next if (byte_size = part.bytesize).zero?
            io_buffer.append byte_size.to_s(16), LINE_END, part, LINE_END
            if io_buffer.length > IO_BUFFER_LEN_MAX
              fast_write_str socket, io_buffer.read_and_reset
            end
          end
          io_buffer.write CLOSE_CHUNKED
        else
          body.each do |part|
            next if part.bytesize.zero?
            io_buffer.write part
            if io_buffer.length > IO_BUFFER_LEN_MAX
              fast_write_str socket, io_buffer.read_and_reset
            end
          end
        end
        fast_write_str(socket, io_buffer.read_and_reset) unless io_buffer.length.zero?
      else
        if chunked
          empty_body = true
          body.each do |part|
            next if part.nil? || (byte_size = part.bytesize).zero?
            empty_body = false
            io_buffer.append byte_size.to_s(16), LINE_END, part, LINE_END
            fast_write_str socket, io_buffer.read_and_reset
          end
          if empty_body
            io_buffer << CLOSE_CHUNKED
            fast_write_str socket, io_buffer.read_and_reset
          else
            fast_write_str socket, CLOSE_CHUNKED
          end
        else
          fast_write_str socket, io_buffer.read_and_reset
          body.each do |part|
            next if part.bytesize.zero?
            fast_write_str socket, part
          end
        end
      end
      socket.flush
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      raise ConnectionError, SOCKET_WRITE_ERR_MSG
    rescue  Errno::EPIPE, SystemCallError, IOError
      raise ConnectionError, SOCKET_WRITE_ERR_MSG
    end

    private :fast_write_str, :fast_write_response

    def normalize_env(env, client)
      if host = env[HTTP_HOST]
        if colon = host.rindex("]:") # IPV6 with port
          env[SERVER_NAME] = host[0, colon+1]
          env[SERVER_PORT] = host[colon+2, host.bytesize]
        elsif !host.start_with?("[") && colon = host.index(":") # not hostname or IPV4 with port
          env[SERVER_NAME] = host[0, colon]
          env[SERVER_PORT] = host[colon+1, host.bytesize]
        else
          env[SERVER_NAME] = host
          env[SERVER_PORT] = default_server_port(env)
        end
      else
        env[SERVER_NAME] = LOCALHOST
        env[SERVER_PORT] = default_server_port(env)
      end

      unless env[REQUEST_PATH]
        uri = begin
          URI.parse(env[REQUEST_URI])
        rescue URI::InvalidURIError
          raise Puma::HttpParserError
        end
        env[REQUEST_PATH] = uri.path

        env[QUERY_STRING] = uri.query if uri.query
      end

      env[PATH_INFO] = env[REQUEST_PATH].to_s # #to_s in case it's nil

      unless env.key?(REMOTE_ADDR)
        begin
          addr = client.peerip
        rescue Errno::ENOTCONN
          if client.peer_family == Socket::AF_INET6
            addr = UNSPECIFIED_IPV6
          else
            addr = UNSPECIFIED_IPV4
          end
        end

        if addr.empty?
          if client.peer_family == Socket::AF_INET6
            addr = LOCALHOST_IPV6
          else
            addr = LOCALHOST_IPV4
          end
        end

        env[REMOTE_ADDR] = addr
      end

      env[HTTP_VERSION] = env[SERVER_PROTOCOL]
    end
    private :normalize_env

    def illegal_header_key?(header_key)
      !!(ILLEGAL_HEADER_KEY_REGEX =~ header_key.to_s)
    end

    def illegal_header_value?(header_value)
      !!(ILLEGAL_HEADER_VALUE_REGEX =~ header_value.to_s)
    end
    private :illegal_header_key?, :illegal_header_value?

    def req_env_post_parse(env)
      to_delete = nil
      to_add = nil

      env.each do |k,v|
        if k.start_with?("HTTP_") && k.include?(",") && k != "HTTP_TRANSFER,ENCODING"
          if to_delete
            to_delete << k
          else
            to_delete = [k]
          end

          unless to_add
            to_add = {}
          end

          to_add[k.tr(",", "_")] = v
        end
      end

      if to_delete
        to_delete.each { |k| env.delete(k) }
        env.merge! to_add
      end
    end
    private :req_env_post_parse

    def str_early_hints(headers)
      eh_str = +""
      headers.each_pair do |k, vs|
        next if illegal_header_key?(k)

        if vs.respond_to?(:to_s) && !vs.to_s.empty?
          vs.to_s.split(NEWLINE).each do |v|
            next if illegal_header_value?(v)
            eh_str << "#{k}: #{v}\r\n"
          end
        elsif !(vs.to_s.empty? || !illegal_header_value?(vs))
          eh_str << "#{k}: #{vs}\r\n"
        end
      end
      eh_str.freeze
    end
    private :str_early_hints

    def fetch_status_code(status)
      HTTP_STATUS_CODES.fetch(status) { CUSTOM_STAT }
    end
    private :fetch_status_code

    def str_headers(env, status, headers, res_body, io_buffer, force_keep_alive)

      line_ending = LINE_END
      colon = COLON

      resp_info = {}
      resp_info[:no_body] = env[REQUEST_METHOD] == HEAD

      http_11 = env[SERVER_PROTOCOL] == HTTP_11
      if http_11
        resp_info[:allow_chunked] = true
        resp_info[:keep_alive] = env.fetch(HTTP_CONNECTION, "").downcase != CLOSE

        if status == 200
          io_buffer << HTTP_11_200
        else
          io_buffer.append "#{HTTP_11} #{status} ", fetch_status_code(status), line_ending

          resp_info[:no_body] ||= status < 200 || STATUS_WITH_NO_ENTITY_BODY[status]
        end
      else
        resp_info[:allow_chunked] = false
        resp_info[:keep_alive] = env.fetch(HTTP_CONNECTION, "").downcase == KEEP_ALIVE

        if status == 200
          io_buffer << HTTP_10_200
        else
          io_buffer.append "HTTP/1.0 #{status} ",
                       fetch_status_code(status), line_ending

          resp_info[:no_body] ||= status < 200 || STATUS_WITH_NO_ENTITY_BODY[status]
        end
      end

      resp_info[:keep_alive] &&= @queue_requests

      resp_info[:keep_alive] &&= force_keep_alive

      resp_info[:response_hijack] = nil

      headers.each do |k, vs|
        next if illegal_header_key?(k)

        case k.downcase
        when CONTENT_LENGTH2
          next if illegal_header_value?(vs)
          resp_info[:content_length] = vs&.to_i
          next
        when TRANSFER_ENCODING
          resp_info[:allow_chunked] = false
          resp_info[:content_length] = nil
          resp_info[:transfer_encoding] = vs
        when HIJACK
          resp_info[:response_hijack] = vs
          next
        when BANNED_HEADER_KEY
          next
        end

        ary = if vs.is_a?(::Array) && !vs.empty?
          vs
        elsif vs.respond_to?(:to_s) && !vs.to_s.empty?
          vs.to_s.split NEWLINE
        else
          nil
        end
        if ary
          ary.each do |v|
            next if illegal_header_value?(v)
            io_buffer.append k, colon, v, line_ending
          end
        else
          io_buffer.append k, colon, line_ending
        end
      end

      if http_11
        io_buffer << CONNECTION_CLOSE if !resp_info[:keep_alive]
      else
        io_buffer << CONNECTION_KEEP_ALIVE if resp_info[:keep_alive]
      end
      resp_info
    end
    private :str_headers
  end
end
