# frozen_string_literal: true

module ZatsuLsp
  module TypeVariable
    class Base
      attr_reader :name, :node, :path, :stable,
                  :candidates, :dependencies, :dependents

      def initialize(path:, name:, node:)
        @path = path
        @name = name
        @node = node

        @candidates = []
        @dependencies = []
        @dependents = []
        @leaf = false
        # @stable = false
      end

      def leaf? = @leaf
      def leaf! = (@leaf = true)

      def id
        @id ||= @node.node_id
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

    class Arg < Base
      attr_reader :method_obj

      def initialize(path:, name:, node:)
        super
        @method_obj = nil
      end

      def add_method_obj(method_obj)
        @method_obj = method_obj
      end

      def inference
        @method_obj.inference_arg_type(@name)
      end
    end

    class LvarWrite < Base
      def inference
        @dependencies[0].inference
      end
    end

    class LvarRead < Base
      def inference
        @dependencies[0].inference
      end
    end

    class Static < Base
      def correct_type(type)
        @candidates[0] = type
      end

      def inference
        @candidates.first
      end
    end

    class Call < Base
      attr_reader :receiver_tv, :args, :scope

      def initialize(path:, name:, node:)
        super
        @receiver_tv = nil
        @args = []
      end

      def add_receiver(receiver_tv)
        @receiver_tv = receiver_tv
        @dependencies << receiver_tv
        receiver_tv.add_dependent(self)
      end

      def add_arg(arg)
        @args << arg
        @dependencies << arg
        arg.add_dependent(self)
      end

      def add_scope(const_name)
        @scope = const_name
      end

      def inference
        receiver_type = @receiver_tv.inference

        if receiver_type.is_a?(Type::Any)
          Type.any
        else
          method_obj = ZatsuLsp.method_registry.find(receiver_type.to_human_s, @name, visibility: :public)
          method_obj.inference_return_type
        end
      end
    end

    class If < Base
      attr_reader :predicate

      def initialize(path:, name:, node:)
        super
        @predicate = nil
      end

      def add_predicate(predicate)
        @predicate = predicate
        predicate.add_dependent(self)
      end

      def inference
        types = @dependencies.map(&:inference)
        if types.size == 1 # if cond without else
          types.push(Type::Nil.new)
        end

        Type::Union.build(types)
      end
    end
  end
end
