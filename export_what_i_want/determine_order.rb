module V
  module_function

  def alidate(val, type)
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
      database.adapter = V.alidate(json["adapter"], :string)
      database.name = V.alidate(json["name"], :string)
      database.encoding = V.alidate(json["encoding"], :string)
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
      table.name = V.alidate(json["name"], :string)
      table.primary_key = V.alidate(json["primary_key"], :string)

      V.alidate(json["belongs_to_relations"], :array)
      table.belongs_to_relations = json["belongs_to_relations"].map { |relation| BelongsToRelation.deserialize(relation) }

      V.alidate(json["polymorphic_as"], :array)
      table.polymorphic_as = json["polymorphic_as"].map { |val| V.alidate(val, :string) }

      V.alidate(json["columns"], :array)
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
end

class BelongsToRelation
  attr_accessor :polymorphic, :polymorphic_name, :foreign_type, :foreign_key, :table_name

  def self.deserialize(json)
    new.tap do |relation|
      relation.polymorphic = V.alidate(json["polymorphic"], :boolean)

      if relation.polymorphic
        relation.polymorphic_name = V.alidate(json["polymorphic_name"], :string)
        relation.foreign_type = V.alidate(json["foreign_type"], :string)
        relation.foreign_key = V.alidate(json["foreign_key"], :string)
      else
        relation.table_name = V.alidate(json["table_name"], :string)
        relation.foreign_key = V.alidate(json["foreign_key"], :string)
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
      column.name = V.alidate(json["name"], :string)
    end
  end

  def serialize
    {
      name: name,
    }
  end
end

module ComputeTableDependencies
  module_function

  def compute_table_dependencies(table, polymorphic_by_name)
    table.belongs_to_relations.each_with_object([]) do |relation, acc|
      if relation.polymorphic
        polymorphic_by_name[relation.polymorphic_name].each do |table_name|
          acc << table_name
        end
      else
        acc << relation.table_name
      end
    end
  end

  def run(tables)
    ordered_table_names = []

    polymorphic_by_name = tables.each_with_object({}) do |table, acc|
      table.polymorphic_as.each do |polymorphic|
        acc[polymorphic] ||= []
        acc[polymorphic] << table.name
      end
    end

    table_by_name = tables.each_with_object({}) do |table, acc|
      acc[table.name] = table
    end

    loop do
      break if table_by_name.empty?

      tables_with_no_dependencies = table_by_name.values.select do |table|
        not_resolved_names = compute_table_dependencies(table, polymorphic_by_name) - ordered_table_names - [table.name]

        not_resolved_names.empty?
      end

      tables_with_no_dependencies.each do |table|
        ordered_table_names << table.name
        table_by_name.delete(table.name)
      end
    end

    ordered_table_names
  end
end

require "json"

json = JSON.parse(File.read("schema.json"))

config = Config.deserialize(json)

ordered_table_names = ComputeTableDependencies.run(config.tables)
pp ordered_table_names
