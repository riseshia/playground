# frozen_string_literal: true

# Backport of Ractor::Port for Ruby 3.3/3.4
#
# Ractor::Port enables message-based communication between Ractors.
# Only the creator Ractor can receive from the port, but any Ractor can send to it.
class Ractor
  class Port
    class ClosedError < StandardError; end
    class PermissionError < StandardError; end

    def initialize
      owner_id = Ractor.current.object_id

      # Create an internal ractor to manage the port's message queue
      # This ractor handles all state management to avoid sharing issues
      @manager = Ractor.new(owner_id) do |owner_id|
        queue = []
        closed = false

        loop do
          cmd, *args = Ractor.receive

          case cmd
          when :send
            if closed
              Ractor.yield [:error, :closed, "The port is already closed"]
            else
              msg = args[0]
              queue << msg
              Ractor.yield [:ok]
            end

          when :receive
            caller_id = args[0]

            # Check if caller is the owner
            if caller_id != owner_id
              Ractor.yield [:error, :permission, "Only the creator Ractor can receive from or close this port"]
              next
            end

            # If queue has messages, return the first one
            unless queue.empty?
              Ractor.yield [:ok, queue.shift]
              next
            end

            # If closed and empty, return error
            if closed
              Ractor.yield [:error, :closed, "The port is closed and empty"]
              next
            end

            # Queue is empty and port is open, need to wait
            # Signal that we're waiting
            Ractor.yield [:waiting]

          when :close
            caller_id = args[0]

            # Check if caller is the owner
            if caller_id != owner_id
              Ractor.yield [:error, :permission, "Only the creator Ractor can receive from or close this port"]
              next
            end

            closed = true
            Ractor.yield [:ok]

          when :closed?
            Ractor.yield [:ok, closed]

          when :shutdown
            break
          end
        end
      end
    end

    # Send a message to the port
    # This operation never blocks as the queue has infinite capacity
    #
    # @param obj [Object] The object to send
    # @return [Port] self
    def send(obj)
      @manager.send([:send, obj])
      status, *rest = @manager.take

      if status == :error
        error_type, message = rest
        raise ClosedError, message if error_type == :closed
        raise PermissionError, message if error_type == :permission
      end

      self
    end
    alias_method :<<, :send

    # Receive a message from the port
    # Blocks if the queue is empty
    # Only the creator Ractor can call this method
    #
    # @return [Object] The received object
    # @raise [PermissionError] if called from a non-owner Ractor
    # @raise [ClosedError] if the port is closed and queue is empty
    def receive
      caller_id = Ractor.current.object_id

      loop do
        @manager.send([:receive, caller_id])
        status, *rest = @manager.take

        case status
        when :ok
          return rest[0]
        when :error
          error_type, message = rest
          raise ClosedError, message if error_type == :closed
          raise PermissionError, message if error_type == :permission
        when :waiting
          # Queue is empty, sleep a bit and retry
          sleep 0.001
        end
      end
    end

    # Close the port
    # Only the creator Ractor can call this method
    # After closing, no more messages can be sent
    #
    # @return [nil]
    # @raise [PermissionError] if called from a non-owner Ractor
    def close
      caller_id = Ractor.current.object_id

      @manager.send([:close, caller_id])
      status, *rest = @manager.take

      if status == :error
        error_type, message = rest
        raise PermissionError, message if error_type == :permission
      end

      nil
    end

    # Check if the port is closed
    #
    # @return [Boolean]
    def closed?
      @manager.send([:closed?])
      status, *rest = @manager.take
      rest[0]
    end
  end
end
