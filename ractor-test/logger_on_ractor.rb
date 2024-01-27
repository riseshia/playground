$stdout.sync = true

require 'logger'

module L
  LoggerRactor = Ractor.new do
    logger = ::Logger.new($stdout)

    loop do
      method, val = Ractor.receive
      logger.send(method, val)
    end
  end

  module Logger
    module_function

    define_method(:info) do |val|
      LoggerRactor.send(:info, val)
    end
  end
end

10.times.map do |i|
  Ractor.new(i) do |i|
    L::Logger.info "Hello, Ractor! #{i}"
  end
end

sleep 1
