# frozen_string_literal: true

module Puma
  class UnsupportedBackend < StandardError; end

  class Reactor
    def initialize(backend, &block)
      require 'nio'
      valid_backends = [:auto, *::NIO::Selector.backends]
      unless valid_backends.include?(backend)
        raise ArgumentError.new("unsupported IO selector backend: #{backend} (available backends: #{valid_backends.join(', ')})")
      end

      @selector = ::NIO::Selector.new(NIO::Selector.backends.delete(backend))
      @input = Queue.new
      @timeouts = []
      @block = block
    end

    def run(background=true)
      if background
        @thread = Thread.new do
          Puma.set_thread_name "reactor"
          select_loop
        end
      else
        select_loop
      end
    end

    def add(client)
      @input << client
      @selector.wakeup
      true
    rescue ClosedQueueError, IOError # Ignore if selector is already closed
      false
    end

    def shutdown
      @input.close
      begin
        @selector.wakeup
      rescue IOError # Ignore if selector is already closed
      end
      @thread&.join
    end

    private

    def select_loop
      close_selector = true
      begin
        until @input.closed? && @input.empty?
          timeout = (earliest = @timeouts.first) && earliest.timeout
          @selector.select(timeout) {|mon| wakeup!(mon.value)}

          timed_out = @timeouts.take_while {|t| t.timeout == 0}
          timed_out.each { |c| wakeup! c }

          unless @input.empty?
            until @input.empty?
              client = @input.pop
              register(client) if client.io_ok?
            end
            @timeouts.sort_by!(&:timeout_at)
          end
        end
      rescue StandardError => e
        STDERR.puts "Error in reactor loop escaped: #{e.message} (#{e.class})"
        STDERR.puts e.backtrace

        if NoMethodError === e
          close_selector = false
        else
          retry
        end
      end
      @timeouts.each(&@block)
      @selector.close if close_selector
    end

    def register(client)
      @selector.register(client.to_io, :r).value = client
      @timeouts << client
    rescue ArgumentError
      # unreadable clients raise error when processed by NIO
    end

    def wakeup!(client)
      if @block.call client
        @selector.deregister client.to_io
        @timeouts.delete client
      end
    end
  end
end
