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

class Database
  attr_accessor :adapter, :name, :encoding

  def self.deserialize(json)
    new.tap do |database|
      database.adapter = V.alidate!(json["adapter"], :string)
      database.name = V.alidate!(json["name"], :string)
      database.encoding = V.alidate!(json["encoding"], :string)
    end
  end

  def serialize
    {
      adapter: adapter,
      name: name,
      encoding: encoding,
    }
  end
end

class Table
  attr_accessor :name, :primary_key, :belongs_to_relations, :polymorphic_as, :columns

  def self.deserialize(json)
    new.tap do |table|
      table.name = V.alidate!(json["name"], :string)
      table.primary_key = V.alidate!(json["primary_key"], :string)

      V.alidate!(json["belongs_to_relations"], :array)
      table.belongs_to_relations = json["belongs_to_relations"].map { |relation| BelongsToRelation.deserialize(relation) }

      V.alidate!(json["polymorphic_as"], :array)
      table.polymorphic_as = json["polymorphic_as"].map { |val| V.alidate!(val, :string) }

      V.alidate!(json["columns"], :array)
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
      key = "#{name}.#{belongs_to_extract_target_table.foreign_key}"
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

class BelongsToRelation
  attr_accessor :polymorphic, :polymorphic_name, :foreign_type, :foreign_key, :table_name

  def self.deserialize(json)
    new.tap do |relation|
      relation.polymorphic = V.alidate!(json["polymorphic"], :boolean)

      if relation.polymorphic
        relation.polymorphic_name = V.alidate!(json["polymorphic_name"], :string)
        relation.foreign_type = V.alidate!(json["foreign_type"], :string)
        relation.foreign_key = V.alidate!(json["foreign_key"], :string)
      else
        relation.table_name = V.alidate!(json["table_name"], :string)
        relation.foreign_key = V.alidate!(json["foreign_key"], :string)
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

class TableColumn
  attr_accessor :name

  def self.deserialize(json)
    new.tap do |column|
      column.name = V.alidate!(json["name"], :string)
    end
  end

  def serialize
    {
      name: name,
    }
  end
end
