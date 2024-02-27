# frozen_string_literal: true
# shareable_constant_value: literal

$stdout.sync = true

require 'logger'

# require 'nbproc'

Message = Data.define(:msg, :event)

class LoggerBackend
  def self.start_server(*args, **kwargs)
    Ractor.new(self, args.freeze, kwargs.freeze) do |klass, args, kwargs|
      obj = klass.new(*args, **kwargs)

      loop do
        msg = Ractor.receive
        obj.handle_call(msg)
      end
    end
  end

  def initialize(logdev)
    @logger = Logger.new(logdev)
  end

  def handle_call(data)
    @logger.send(data.msg, data.event)
  end

  def call(event)
    @r.send(event)
  end
end

module RactorLogger
  module_function

  BACKENDS_RACTOR = Ractor.new do
    backends = []

    loop do
      message = Ractor.receive

      case message.msg
      when :add_backend
        backends << message.event
      when :broadcast
        backends.each do |backend|
          backend << message.event
        end
      end
    end
  end

  def info(str)
    msg = Message.new(:info, str)
    BACKENDS_RACTOR << Message.new(:broadcast, msg)
  end

  def add_backend(backend)
    BACKENDS_RACTOR << Message.new(:add_backend, backend)
  end
end

backend = LoggerBackend.start_server($stdout)
RactorLogger.add_backend(backend)

10.times.map do |i|
  text = "Hello, Ractor! from main ractor#{i}"
  RactorLogger.info(text)
  msg = Message.new(:info, text)
  backend.send(msg)
end

10.times.map do |i|
  Ractor.new(i) do |i|
    RactorLogger.info("Hello, Ractor! from sub ractor#{i}")
  end
end

sleep 2
