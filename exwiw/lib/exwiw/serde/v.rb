# frozen_string_literal: true

module Exwiw
  module Serde
    module V
      module_function

      def alidate!(val, type)
        ret =
          case type
          when :string
            val.is_a?(String)
          when :integer
            val.is_a?(Integer)
          when :array
            val.is_a?(Array)
          when :boolean
            [true, false].include?(val)
          end

        raise "Invalid type passed: #{val}, expected: #{type}, actual: #{val.class}" unless ret

        val
      end
    end
  end
end
