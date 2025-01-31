# frozen_string_literal: true

module Exwiw
  class TableColumn
    attr_accessor :name

    def self.deserialize(json)
      new.tap do |column|
        column.name = Serde::V.alidate!(json["name"], :string)
      end
    end

    def serialize
      {
        name: name,
      }
    end
  end
end
