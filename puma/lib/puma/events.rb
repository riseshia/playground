# frozen_string_literal: true

module Puma
  class Events
    def initialize
      @hooks = Hash.new { |h,k| h[k] = [] }
    end

    def fire(hook, *args)
      @hooks[hook].each { |t| t.call(*args) }
    end

    def register(hook, obj=nil, &blk)
      if obj and blk
        raise "Specify either an object or a block, not both"
      end

      h = obj || blk

      @hooks[hook] << h

      h
    end

    def on_booted(&block)
      register(:on_booted, &block)
    end

    def on_restart(&block)
      register(:on_restart, &block)
    end

    def on_stopped(&block)
      register(:on_stopped, &block)
    end

    def fire_on_booted!
      fire(:on_booted)
    end

    def fire_on_restart!
      fire(:on_restart)
    end

    def fire_on_stopped!
      fire(:on_stopped)
    end
  end
end
