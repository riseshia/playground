# frozen_string_literal: true

require_relative "serde/v"

module Exwiw
  module Serde
    TypeError = Class.new(StandardError)

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def attribute(name, type, options = {})
        attr_reader name

        _serde_attrs[name] = { type: type, options: options }
        _serde_deserialize_keymap[name.to_s] = name

        define_method("#{name}=") do |value|
          if value.is_a?(type)
            instance_variable_set("@#{name}", value)
          else
            raise TypeError, "Expected #{self.class}##{name} to be a #{type}, but got #{value.class}"
          end
        end
      end

      private def _serde_attrs
        @_serde_attrs ||= {}
      end

      private def _serde_deserialize_keymap
        @_serde_deserialize_keymap ||= {}
      end

      def from(obj)
        method_name = build_from_method_name(obj)

        if obj.class == self.class
          obj.clone
        elsif respond_to?(method_name)
          __send__(method_name, obj)
        else
          raise "Naiyo"
        end
      end

      def from_hash(from_obj)
        new.tap do |obj|
          _serde_deserialize_keymap.each do |from_key, to_key|
            from_value = from_obj[from_key]
            obj.__send__("#{to_key}=", from_value)
          end
        end
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

      private def _serde_attrs
        @_serde_attrs ||= {}
      end
    end
  end
end
