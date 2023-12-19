# frozen_string_literal: true

require_relative 'null_io'
require_relative 'error_logger'
require 'stringio'
require 'io/wait' unless Puma::HAS_NATIVE_IO_WAIT

module Puma
  class LogWriter
    class DefaultFormatter
      def call(str)
        str
      end
    end

    class PidFormatter
      def call(str)
        "[#{$$}] #{str}"
      end
    end

    LOG_QUEUE = Queue.new

    attr_reader :stdout,
                :stderr

    attr_accessor :formatter, :custom_logger

    def initialize(stdout, stderr)
      @formatter = DefaultFormatter.new
      @custom_logger = nil
      @stdout = stdout
      @stderr = stderr

      @debug = ENV.key?('PUMA_DEBUG')
      @error_logger = ErrorLogger.new(@stderr)
    end

    DEFAULT = new(STDOUT, STDERR)

    def self.strings
      LogWriter.new(StringIO.new, StringIO.new)
    end

    def self.stdio
      LogWriter.new($stdout, $stderr)
    end

    def self.null
      n = NullIO.new
      LogWriter.new(n, n)
    end

    def log(str)
      if @custom_logger&.respond_to?(:write)
        @custom_logger.write(format(str))
      else
        internal_write "#{@formatter.call str}\n"
      end
    end

    def write(str)
      internal_write @formatter.call(str)
    end

    def internal_write(str)
      LOG_QUEUE << str
      while (w_str = LOG_QUEUE.pop(true)) do
        begin
          @stdout.is_a?(IO) and @stdout.wait_writable(1)
          @stdout.write w_str
          @stdout.flush unless @stdout.sync
        rescue Errno::EPIPE, Errno::EBADF, IOError, Errno::EINVAL
        # 'Invalid argument' (Errno::EINVAL) may be raised by flush
        end
      end
    rescue ThreadError
    end
    private :internal_write

    def debug?
      @debug
    end

    def debug(str)
      log("% #{str}") if @debug
    end

    # Write +str+ to +@stderr+
    def error(str)
      @error_logger.info(text: @formatter.call("ERROR: #{str}"))
      exit 1
    end

    def format(str)
      formatter.call(str)
    end

    def connection_error(error, req, text="HTTP connection error")
      @error_logger.info(error: error, req: req, text: text)
    end

    def parse_error(error, req)
      @error_logger.info(error: error, req: req, text: 'HTTP parse error, malformed request')
    end

    def ssl_error(error, ssl_socket)
      peeraddr = ssl_socket.peeraddr.last rescue "<unknown>"
      peercert = ssl_socket.peercert
      subject = peercert&.subject
      @error_logger.info(error: error, text: "SSL error, peer: #{peeraddr}, peer cert: #{subject}")
    end

    def unknown_error(error, req=nil, text="Unknown error")
      @error_logger.info(error: error, req: req, text: text)
    end

    def debug_error(error, req=nil, text="")
      @error_logger.debug(error: error, req: req, text: text)
    end
  end
end
