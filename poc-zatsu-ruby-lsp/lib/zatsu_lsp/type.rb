# frozen_string_literal: true

module ZatsuLsp
  module Type
    class Base
      def to_human_s
        raise NotImplementedError
      end
    end

    class Any < Base
      def to_human_s
        "any"
      end
    end

    class Nil < Base
      def to_human_s
        "nil"
      end
    end

    class True < Base
      def to_human_s
        "true"
      end
    end

    class False < Base
      def to_human_s
        "false"
      end
    end

    class Integer < Base
      def to_human_s
        "Integer"
      end
    end

    class Union < Base
      attr_reader :element_types

      def initialize(element_types)
        super()
        @element_types = element_types
      end

      def to_human_s
        @element_types.map(&:to_human_s).join(' | ')
      end

      class << self
        def build(types)
          element_types = []
          types.each do |type|
            if type.is_a?(Union)
              element_types.concat(type.element_types)
            else
              element_types << type
            end
          end

          new(element_types)
        end
      end
    end

    class Array < Base
      def initialize(element_types)
        super
        @element_types = element_types
      end

      def to_human_s
        "[#{@element_types.map(&:to_human_s).join(' | ')}]"
      end
    end

    class Hash < Base
      def initialize(key_types, value_types)
        super
        @key_types = key_types
        @value_types = value_types
      end

      def to_human_s
        key_types = @key_types.map(&:to_human_s).join(' | ')
        value_types = @value_types.map(&:to_human_s).join(' | ')
        "{#{key_types} => #{value_types}}"
      end
    end

    module_function

    def any = (@any ||= Any.new)
    def nil = (@nil ||= Nil.new)
    def true = (@true ||= True.new)
    def false = (@false ||= False.new)
    def integer = (@integer ||= Integer.new)
  end
end
