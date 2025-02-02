# frozen_string_literal: true

require_relative "serde/v"

module Exwiw
  module Serde
    TypeError = Class.new(StandardError)
    RequiredAttributeError = Class.new(StandardError)
    DeclareError = Class.new(StandardError)

    Boolean = [TrueClass, FalseClass].freeze

    # OptionalType is used to mark an attribute as optional.
    class OptionalType
      attr_reader :base_type

      def initialize(base_type)
        @base_type = base_type
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def optional(type)
        OptionalType.new(type)
      end

      def attribute(name, type, options = {})
        attr_reader name

        if type.is_a?(Array) && type.size != 1
          raise Exwiw::Serde::DeclareError, "Array type must have exactly one type in the array"
        end

        _serde_attrs[name] = { type: type, options: options }
        _serde_deserialize_keymap[name.to_s] = name

        define_method("#{name}=") do |value|
          if type.is_a?(Exwiw::Serde::OptionalType)
            # For optional attributes: nil is allowed, otherwise verify against the base_type.
            if value.nil? || self.class.send(:valid_type?, value, type.base_type)
              instance_variable_set("@#{name}", value)
            else
              raise Exwiw::Serde::TypeError, "Expected #{self.class}##{name} to be a #{type.base_type} (or nil), but got #{value.class}"
            end
          else
            if value.nil?
              raise Exwiw::Serde::TypeError, "Missing required attribute '#{name}' for #{self.class}"
            elsif self.class.send(:valid_type?, value, type)
              instance_variable_set("@#{name}", value)
            else
              raise Exwiw::Serde::TypeError, "Expected #{self.class}##{name} to be a #{type}, but got #{value.class}"
            end
          end
        end
      end

      def valid_type?(value, type)
        if type == Boolean
          # Boolean type: allow only true or false.
          return value.is_a?(TrueClass) || value.is_a?(FalseClass)
        elsif type.is_a?(Array)
          if type.size == 1
            # Single-element array type: value must be an Array and all elements must be instances of type.first.
            return false unless value.is_a?(::Array)
            return value.all? { |v| v.is_a?(type.first) }
          else
            # Multi-element array type: for union types like Boolean, check if value is an instance of any type.
            return type.any? { |t| value.is_a?(t) }
          end
        else
          value.is_a?(type)
        end
      end

      private def _serde_attrs
        @_serde_attrs ||= {}
      end

      private def _serde_deserialize_keymap
        @_serde_deserialize_keymap ||= {}
      end

      def from_hash(from_obj)
        new.tap do |obj|
          _serde_deserialize_keymap.each do |from_key, to_key|
            from_value = from_obj[from_key]
            to_type = _serde_attrs[to_key][:type]

            if from_value.class == to_type
              obj.__send__("#{to_key}=", from_value.dup)
              next
            end

            if to_type.is_a?(Array)
              el_type = to_type.first
              method_name = build_from_method_name(from_value)
            else
              method_name = build_from_method_name(from_value)
              if to_type.respond_to?(method_name)
                value = to_type.__send__(method_name, from_value)
                obj.__send__("#{to_key}=", value)
              else
                raise "#{to_type} does not respond to #{method_name}"
              end
            end
          end
        end
      end

      private def deserialize(from_obj, to_type)
      end

      def to(target_class = Hash)
        method_name = build_to_method_name(obj)

        if obj.class == self.class
          obj.clone
        elsif respond_to?(method_name)
          __send__(method_name, obj)
        else
          raise "Naiyo"
        end
      end

      def build_from_method_name(obj)
        suffix = obj.class.name.downcase.gsub("::", "__")
        "from_#{suffix}"
      end

      def build_to_method_name(obj)
        suffix = obj.class.name.downcase.gsub("::", "__")
        "to_#{suffix}"
      end
    end
  end
end
