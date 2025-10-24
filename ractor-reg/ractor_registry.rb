# frozen_string_literal: true

# RactorRegistry - Elixir Registry inspired implementation using Ruby Ractor
#
# A registry for managing Ractor instances by name (unique keys only).
# Provides register, lookup, and unregister functionality via message passing.
class RactorRegistry
  class RegistryError < StandardError; end
  class AlreadyRegisteredError < RegistryError; end
  class NotFoundError < RegistryError; end

  def initialize
    @registry_ractor = Ractor.new do
      registry = {}

      loop do
        message = Ractor.receive
        command, *args = message

        case command
        when :register
          name, ractor, sender = args
          if registry.key?(name)
            sender.send([:error, "Already registered: #{name}"])
          else
            registry[name] = ractor
            sender.send([:ok])
          end

        when :lookup
          name, sender = args
          if registry.key?(name)
            sender.send([:ok, registry[name]])
          else
            sender.send([:error, "Not found: #{name}"])
          end

        when :unregister
          name, sender = args
          if registry.key?(name)
            registry.delete(name)
            sender.send([:ok])
          else
            sender.send([:error, "Not found: #{name}"])
          end

        when :list_all
          sender = args[0]
          sender.send([:ok, registry.keys])

        when :count
          sender = args[0]
          sender.send([:ok, registry.size])

        when :stop
          sender = args[0]
          sender.send([:ok])
          break
        end
      end
    end
  end

  # Register a Ractor with a given name
  # @param name [Symbol, String] The name to register
  # @param ractor [Ractor] The Ractor instance to register
  # @raise [AlreadyRegisteredError] if the name is already registered
  def register(name, ractor)
    sender = Ractor.current
    @registry_ractor.send([:register, name, ractor, sender])
    status, message = Ractor.receive

    if status == :error
      raise AlreadyRegisteredError, message
    end

    true
  end

  # Lookup a Ractor by name
  # @param name [Symbol, String] The name to lookup
  # @return [Ractor, nil] The registered Ractor or nil if not found
  def lookup(name)
    sender = Ractor.current
    @registry_ractor.send([:lookup, name, sender])
    status, result = Ractor.receive

    if status == :error
      nil
    else
      result
    end
  end

  # Lookup a Ractor by name (raising version)
  # @param name [Symbol, String] The name to lookup
  # @return [Ractor] The registered Ractor
  # @raise [NotFoundError] if the name is not registered
  def lookup!(name)
    sender = Ractor.current
    @registry_ractor.send([:lookup, name, sender])
    status, result = Ractor.receive

    if status == :error
      raise NotFoundError, result
    else
      result
    end
  end

  # Unregister a Ractor by name
  # @param name [Symbol, String] The name to unregister
  # @return [Boolean] true if unregistered, false if not found
  def unregister(name)
    sender = Ractor.current
    @registry_ractor.send([:unregister, name, sender])
    status, message = Ractor.receive

    status == :ok
  end

  # List all registered names
  # @return [Array] Array of registered names
  def list_all
    sender = Ractor.current
    @registry_ractor.send([:list_all, sender])
    _status, names = Ractor.receive
    names
  end

  # Count of registered Ractors
  # @return [Integer] Number of registered Ractors
  def count
    sender = Ractor.current
    @registry_ractor.send([:count, sender])
    _status, count = Ractor.receive
    count
  end

  # Stop the registry
  def stop
    sender = Ractor.current
    @registry_ractor.send([:stop, sender])
    Ractor.receive
    true
  end
end
