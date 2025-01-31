# frozen_string_literal: true

module Exwiw
  class Config
    attr_accessor :database, :tables

    def self.deserialize(json)
      new.tap do |config|
        config.database = Database.deserialize(json["database"])
        config.tables = json["tables"].map { |table| Table.deserialize(table) }
      end
    end

    def serialize
      {
        database: database.serialize,
        tables: tables.map(&:serialize),
      }
    end
  end
end
