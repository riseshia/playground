require_relative './visitor'

def parse_rb(file, visitor)
  parse_result = Prism.parse_file(file)
  parse_result.value.accept(visitor)
end

target_project_paths = ARGV
visitor = Visitor.new

target_project_paths.each do |target_project_path|
  Dir.glob("#{target_project_path}**/*.rb").each do |file|
    compact_path = file.gsub(target_project_path, '')
    visitor.file_path = compact_path
    parse_rb(file, visitor)
  end
end

puts "Method defs: #{visitor.method_defs.size}"
puts "Method calls(lvar read, call chain only): #{visitor.method_calls.size}"

method_defs_by_name = visitor.method_defs.group_by(&:name)
puts "Unique method names: #{method_defs_by_name.size}"

called_method_names = visitor.method_calls.map(&:name).uniq
puts "Called method names: #{called_method_names.size}"

called_method_names_by_candidate_count = Hash.new([])
method_def_not_found = []

called_method_names.each do |name|
  if method_defs_by_name[name]
    cand_count = method_defs_by_name[name].size
    called_method_names_by_candidate_count[cand_count] << name
  else
    method_def_not_found.push(name)
  end
end

called_method_names_by_candidate_count.keys.sort.each do |cand_count|
  puts "#{cand_count} candidates: #{called_method_names_by_candidate_count[cand_count].size}"
end
puts "Method def not found: #{method_def_not_found.size}"
