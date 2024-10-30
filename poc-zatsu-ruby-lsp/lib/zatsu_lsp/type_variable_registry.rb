# frozen_string_literal: true

module ZatsuLsp
  class TypeVariableRegistry
    def initialize
      @registry = {}
    end

    def add(var)
      @registry[var.id] = var
    end

    def remove(node_id)
      @registry.delete(node_id)
    end

    def find(node_id)
      @registry[node_id]
    end

    def all_keys
      @registry.keys
    end

    def clear
      @registry.clear
    end
  end
end
