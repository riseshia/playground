# frozen_string_literal: true

module Puma
  class CommonLogger
    FORMAT = %{%s - %s [%s] "%s %s%s %s" %d %s %0.4f\n}

    HIJACK_FORMAT = %{%s - %s [%s] "%s %s%s %s" HIJACKED -1 %0.4f\n}

    LOG_TIME_FORMAT = '%d/%b/%Y:%H:%M:%S %z'

    CONTENT_LENGTH       = 'Content-Length'

    HTTP_VERSION         = Const::HTTP_VERSION
    HTTP_X_FORWARDED_FOR = Const::HTTP_X_FORWARDED_FOR
    PATH_INFO            = Const::PATH_INFO
    QUERY_STRING         = Const::QUERY_STRING
    REMOTE_ADDR          = Const::REMOTE_ADDR
    REMOTE_USER          = 'REMOTE_USER'
    REQUEST_METHOD       = Const::REQUEST_METHOD

    def initialize(app, logger = nil)
      @app = app
      @logger = logger
    end

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      header = Util::HeaderHash.new(header)

      if env['rack.hijack_io']
        log_hijacking(env, 'HIJACK', header, began_at)
      else
        ary = env['rack.after_reply']
        ary << lambda { log(env, status, header, began_at) }
      end

      [status, header, body]
    end

    private

    def log_hijacking(env, status, header, began_at)
      now = Time.now

      msg = HIJACK_FORMAT % [
        env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR] || "-",
        env[REMOTE_USER] || "-",
        now.strftime(LOG_TIME_FORMAT),
        env[REQUEST_METHOD],
        env[PATH_INFO],
        env[QUERY_STRING].empty? ? "" : "?#{env[QUERY_STRING]}",
        env[HTTP_VERSION],
        now - began_at
      ]

      write(msg)
    end

    def log(env, status, header, began_at)
      now = Time.now
      length = extract_content_length(header)

      msg = FORMAT % [
        env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR] || "-",
        env[REMOTE_USER] || "-",
        now.strftime(LOG_TIME_FORMAT),
        env[REQUEST_METHOD],
        env[PATH_INFO],
        env[QUERY_STRING].empty? ? "" : "?#{env[QUERY_STRING]}",
        env[HTTP_VERSION],
        status.to_s[0..3],
        length,
        now - began_at
      ]

      write(msg)
    end

    def write(msg)
      logger = @logger || env['rack.errors']

      if logger.respond_to?(:write)
        logger.write(msg)
      else
        logger << msg
      end
    end

    def extract_content_length(headers)
      value = headers[CONTENT_LENGTH] or return '-'
      value.to_s == '0' ? '-' : value
    end
  end
end
