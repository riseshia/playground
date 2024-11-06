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

    class Integer < Base
      def to_human_s
        "Integer"
      end
    end

    class Union < Base
      def initialize(element_types)
        super
        @element_types = element_types
      end

      def to_human_s
        @element_types.map(&:to_human_s).join(' | ')
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

    def any
      Any.new
    end
  end
end
