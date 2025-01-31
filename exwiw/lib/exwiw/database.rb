# frozen_string_literal: true

module Exwiw
  class Database
    attr_accessor :adapter, :name, :encoding

    def self.deserialize(json)
      new.tap do |database|
        database.adapter = Serde::V.alidate!(json["adapter"], :string)
        database.name = Serde::V.alidate!(json["name"], :string)
      end
    end

    def serialize
      {
        adapter: adapter,
        name: name,
      }
    end
  end
end
