# frozen_string_literal: true

module ZatsuLsp
  module Type
    class Any
      def to_human_s
        "any"
      end
    end

    class Nil
      def to_human_s
        "nil"
      end
    end

    class Union
      def initialize(element_types)
        @element_types = element_types
      end

      def to_human_s
        @element_types.map(&:to_human_s).join(' | ')
      end
    end

    class Array
      def initialize(element_types)
        @element_types = element_types
      end

      def to_human_s
        "[#{@element_types.map(&:to_human_s).join(' | ')}]"
      end
    end

    class Hash
      def initialize(key_types, value_types)
        @key_types = key_types
        @value_types = value_types
      end

      def to_human_s
        key_types = @key_types.map(&:to_human_s).join(' | ')
        value_types = @value_types.map(&:to_human_s).join(' | ')
        "{#{key_types} => #{value_types}}"
      end
    end
  end
end
