# frozen_string_literal: true

module Exwiw
  class BelongsToRelation
    attr_accessor :polymorphic, :polymorphic_name, :foreign_type, :foreign_key, :table_name

    def self.deserialize(json)
      new.tap do |relation|
        relation.polymorphic = Serde::V.alidate!(json["polymorphic"], :boolean)

        if relation.polymorphic
          relation.polymorphic_name = Serde::V.alidate!(json["polymorphic_name"], :string)
          relation.foreign_type = Serde::V.alidate!(json["foreign_type"], :string)
          relation.foreign_key = Serde::V.alidate!(json["foreign_key"], :string)
        else
          relation.table_name = Serde::V.alidate!(json["table_name"], :string)
          relation.foreign_key = Serde::V.alidate!(json["foreign_key"], :string)
        end
      end
    end

    def serialize
      if polymorphic
        {
          polymorphic: polymorphic,
          polymorphic_name: polymorphic_name,
          foreign_type: foreign_type,
          foreign_key: foreign_key,
        }
      else
        {
          polymorphic: polymorphic,
          foreign_key: foreign_key,
          table_name: table_name,
        }
      end
    end
  end
end
