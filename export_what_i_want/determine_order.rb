require "json"

require_relative "./models"
require_relative "./util"

extract_target_table = "companies"
extract_target_ids = [1]

json = JSON.parse(File.read("schema.json"))

config = Config.deserialize(json)

ordered_table_names = ComputeTableDependencies.run(config.tables)

tables_by_name = config.tables.each_with_object({}) do |table, acc|
  acc[table.name] = table
end

ordered_table_names.each do |table_name|
  table = tables_by_name[table_name]

  table.build_extract_query(extract_target_table, extract_target_ids, tables_by_name)
end
