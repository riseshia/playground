# frozen_string_literal: true

module ZatsuLsp
  class MethodRegistry
    def initialize
      @registry = {}
    end

    def add(const_name, node, path, singleton:)
      id = build_id(const_name, node.name, singleton: singleton)

      @registry[id] = Method.new(
        path: path,
        node: node,
        receiver_type: Type::Const.new(const_name),
      )
    end

    def remove(const_name, method_name)
      singleton = node.receiver&.is_a?(Prism::SelfNode)
      id = build_id(const_name, method_name, singleton: singleton)

      @registry.delete(id)
    end

    def find(const_name, method_name, visibility:, singleton: false)
      id = build_id(const_name, method_name, singleton: singleton)
      @registry[id]
    end

    def all_keys
      @registry.keys
    end

    def clear
      @registry.clear
    end

    def guess_method(name)
      candidates = @registry.values.select { |v| v.name == name }

      if candidates.size == 1
        candidates.values.first
      else
        nil
      end
    end

    private def build_id(const_name, method_name, singleton:)
      middle = singleton ? "." : "#"
      "#{const_name}#{middle}#{method_name}"
    end
  end
end
