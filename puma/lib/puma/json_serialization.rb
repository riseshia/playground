# frozen_string_literal: true
require 'stringio'

module Puma
  module JSONSerialization
    QUOTE = /"/
    BACKSLASH = /\\/
    CONTROL_CHAR_TO_ESCAPE = /[\x00-\x1F]/ # As required by ECMA-404
    CHAR_TO_ESCAPE = Regexp.union QUOTE, BACKSLASH, CONTROL_CHAR_TO_ESCAPE

    class SerializationError < StandardError; end

    class << self
      def generate(value)
        StringIO.open do |io|
          serialize_value io, value
          io.string
        end
      end

      private

      def serialize_value(output, value)
        case value
        when Hash
          output << '{'
          value.each_with_index do |(k, v), index|
            output << ',' if index != 0
            serialize_object_key output, k
            output << ':'
            serialize_value output, v
          end
          output << '}'
        when Array
          output << '['
          value.each_with_index do |member, index|
            output << ',' if index != 0
            serialize_value output, member
          end
          output << ']'
        when Integer, Float
          output << value.to_s
        when String
          serialize_string output, value
        when true
          output << 'true'
        when false
          output << 'false'
        when nil
          output << 'null'
        else
          raise SerializationError, "Unexpected value of type #{value.class}"
        end
      end

      def serialize_string(output, value)
        output << '"'
        output << value.gsub(CHAR_TO_ESCAPE) do |character|
          case character
          when BACKSLASH
            '\\\\'
          when QUOTE
            '\\"'
          when CONTROL_CHAR_TO_ESCAPE
            '\u%.4X' % character.ord
          end
        end
        output << '"'
      end

      def serialize_object_key(output, value)
        case value
        when Symbol, String
          serialize_string output, value.to_s
        else
          raise SerializationError, "Could not serialize object of type #{value.class} as object key"
        end
      end
    end
  end
end
