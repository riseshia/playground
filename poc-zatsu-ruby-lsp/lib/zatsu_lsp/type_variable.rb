# frozen_string_literal: true

module ZatsuLsp
  module TypeVariable
    class Base
      attr_reader :id, :candidates, :depends, :affect_to, :node, :path, :stable

      def initialize(
        const_name:,
        method_name:,
        singleton:,
        path:,
        name:,
        node:
      )
        @id = build_id(const_name, method_name, singleton, name)
        @path = path
        @node = node
        @candidates = []
        @depends = []
        @affect_to = []
        @stable = false
      end

      private def build_id(const_name, method_name, singleton, name)
        middle = singleton ? "." : "#"
        "#{const_name}#{middle}#{method_name}_#{name}"
      end
    end

    class LocalVar < Base
    end
  end
end
