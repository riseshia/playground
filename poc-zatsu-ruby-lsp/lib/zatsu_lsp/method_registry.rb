# frozen_string_literal: true

module ZatsuLsp
  class MethodRegistry
    def initialize
      @registry = {}
    end

    def add(const_name, node, path)
      @registry[const_name] = Node::Node.new(path, node)
    end

    def remove(const_name)
      @registry.delete(const_name)
    end

    def find(const_name)
      @registry[const_name]
    end

    def all_keys
      @registry.keys
    end

    def clear
      @registry.clear
    end
  end
end
