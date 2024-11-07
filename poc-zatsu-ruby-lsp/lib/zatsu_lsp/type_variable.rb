# frozen_string_literal: true

module ZatsuLsp
  module TypeVariable
    class Base
      attr_reader :id, :name, :node, :path, :stable,
                  :candidates, :dependencies, :dependents

      def initialize(path:, name:, node:)
        @id = node.node_id
        @path = path
        @name = name
        @node = node

        @candidates = []
        @dependencies = []
        @dependents = []
        # @stable = false
      end

      def add_dependency(type_var)
        @dependencies << type_var
      end

      def add_dependent(type_var)
        @dependents << type_var
      end

      def inference
        raise NotImplementedError
      end
    end

    class Arg < Base; end
    class LvarWrite < Base; end
    class LvarRead < Base; end

    class Static < Base
      def correct_type(type)
        @candidates << type
      end

      def inference
        @candidates.first.to_human_s
      end
    end

    class Call < Base
      attr_reader :receiver, :args, :scope

      def initialize(path:, name:, node:)
        super
        @receiver = nil
        @args = []
      end

      def add_receiver(receiver)
        @receiver = receiver
        @dependencies << receiver
        receiver.add_dependent(self)
      end

      def add_arg(arg)
        @args << arg
        @dependencies << arg
        arg.add_dependent(self)
      end

      def add_scope(const_name)
        @scope = const_name
      end
    end
  end
end
