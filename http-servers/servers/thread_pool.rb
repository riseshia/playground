# frozen_string_literal: true

require 'socket'

class ThreadPool
  attr_accessor :queue, :running, :size

  def initialize(size:)
    self.size = size

    # threadsafe queue to manage work
    self.queue = Queue.new

    size.times do
      Thread.new(self.queue) do |queue|
        # "catch" in Ruby is a lesser known
        # way to change flow of the program,
        # similar to propagating exceptions
        catch(:exit) do
          loop do
            # `pop` blocks until there's
            # something in the queue
            task = queue.pop
            task.call
          end
        end
      end
    end
  end

  def perform(&block)
    self.queue << block
  end

  def shutdown
    size.times do
      # this is going to make threads
      # break out of the infinite loop
      perform { throw :exit }
    end
  end
end
