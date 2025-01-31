# frozen_string_literal: true

module Exwiw
  class Table
    attr_accessor :name, :primary_key, :belongs_to_relations, :polymorphic_as, :columns

    def self.deserialize(json)
      new.tap do |table|
        table.name = Serde::V.alidate!(json["name"], :string)
        table.primary_key = Serde::V.alidate!(json["primary_key"], :string)

        Serde::V.alidate!(json["belongs_to_relations"], :array)
        table.belongs_to_relations = json["belongs_to_relations"].map { |relation| BelongsToRelation.deserialize(relation) }

        Serde::V.alidate!(json["polymorphic_as"], :array)
        table.polymorphic_as = json["polymorphic_as"].map { |val| Serde::V.alidate!(val, :string) }

        Serde::V.alidate!(json["columns"], :array)
        table.columns = json["columns"].map { |column| TableColumn.deserialize(column) }
      end
    end

    def serialize
      {
        name: name,
        primary_key: primary_key,
        belongs_to_relations: belongs_to_relations.map(&:serialize),
        polymorphic_as: polymorphic_as,
        columns: columns.map(&:serialize),
      }
    end

    def column_names
      columns.map(&:name)
    end

    def build_extract_query(extract_target_table, extract_target_ids, tables_by_name)
      # target is itself
      if name == extract_target_table
        return [{
          from: name,
          where: [{ primary_key => extract_target_ids }],
          join: [],
          select: column_names,
        }]
      end

      # it is not related to target table
      if belongs_to_relations.empty?
        return [{
          from: name,
          where: [],
          join: [],
          select: column_names,
        }]
      end

      belongs_to_extract_target_table = belongs_to_relations.find { |relation| relation.table_name == extract_target_table }
      if belongs_to_extract_target_table
        key = belongs_to_extract_target_table.foreign_key
        return [{ from: name, where: [{ key => extract_target_ids }], join: [], select: column_names }]
      end

      ret = compute_dependency_to_table(extract_target_table, tables_by_name)

      if ret.empty?
        [{
          from: name,
          where: [],
          join: [],
          select: column_names,
        }]
      else
        last = ret.last
        last[:where] = [{ last[:foreign_key] => extract_target_ids }]
        ret
      end
    end

    def compute_dependency_to_table(target_table_name, tables_by_name)
      return [] if belongs_to_relations.empty?

      results = belongs_to_relations.map do |relation|
        # XXX: ignore polymorphic for now. to be implemented
        next if relation.polymorphic

        relation_table = tables_by_name[relation.table_name]

        if relation_table.name == target_table_name
          [{ base_table_name: name, foreign_key: relation.foreign_key,
             join_table_name: target_table_name, join_key: relation_table.primary_key }]
        else
          ret = relation_table.compute_dependency_to_table(target_table_name, tables_by_name)
          [{ base_table_name: name, foreign_key: relation.foreign_key,
             join_table_name: relation_table.name, join_key: relation_table.primary_key }] + ret
        end
      end.compact

      matched_dependencies = results.select do |dependency|
        dependency.last[:join_table_name] == target_table_name
      end

      return [] if matched_dependencies.empty?

      matched_dependencies.min_by(&:size)
    end
  end
end
