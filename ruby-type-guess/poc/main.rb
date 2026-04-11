#!/usr/bin/env ruby
# PoC メインエントリ: ターゲットプロジェクトの型情報を収集・表示する

require "prism"
require_relative "type_world"
require_relative "world_builder"
require_relative "type_inferrer"

TARGET_DIR = File.expand_path("../target", __dir__)

# === Phase 1: eval + reflection で「世界」を構築 ===

puts "=== Phase 1: Building Type World ==="
puts

builder = TypeGuess::WorldBuilder.new

world = builder.build(
  framework_files: [
    "#{TARGET_DIR}/lib/mini_active_record",
    "#{TARGET_DIR}/lib/mini_active_support",
  ],
  schema_files: [
    "#{TARGET_DIR}/db/schema",
  ],
  model_files: [
    "#{TARGET_DIR}/app/models/concerns/searchable.rb",
    "#{TARGET_DIR}/app/models/user.rb",
    "#{TARGET_DIR}/app/models/post.rb",
    "#{TARGET_DIR}/app/models/comment.rb",
    "#{TARGET_DIR}/app/models/category.rb",
  ]
)

if builder.errors.any?
  puts "Errors during eval:"
  builder.errors.each { |e| puts "  #{e}" }
  puts
end

# 世界の内容を表示
puts "--- Discovered Classes ---"
world.classes.each do |name, info|
  puts
  puts "#{name} < #{info.superclass}"
  puts "  ancestors: #{info.ancestors.join(' > ')}"
  puts "  instance_methods(false):"
  info.instance_methods.each do |mname, minfo|
    loc = minfo.source_location&.join(":") || "(native)"
    params = minfo.parameters.map { |k, n| "#{k}:#{n}" }.join(", ")
    puts "    ##{mname}(#{params})  @ #{loc}"
  end
  puts "  singleton_methods(false):"
  info.singleton_methods.each do |mname, minfo|
    loc = minfo.source_location&.join(":") || "(native)"
    puts "    .#{mname}  @ #{loc}"
  end
end

# === Phase 2: AST 解析でメソッド本文の型推論 ===

puts
puts "=== Phase 2: Type Inference in Method Bodies ==="
puts

inferrer = TypeGuess::TypeInferrer.new(world)

model_files = Dir.glob("#{TARGET_DIR}/app/models/*.rb")
model_files.each do |file|
  inferrer.analyze_file(file)
end

# 型マップの中から、メソッド本文内のローカル変数を表示
puts "--- Type Map (local variables in method bodies) ---"
puts

inferrer.type_map.each do |key, info|
  next unless info.type  # 型不明はスキップ
  # ローカル変数の代入・参照を表示
  short_file = info.file.sub(TARGET_DIR + "/", "")
  printf "  %-45s  %-30s  → %s\n", "#{short_file}:#{info.line}:#{info.column}", info.expression, info.type
end

# === 対話的クエリ ===

puts
puts "=== Query Mode ==="
puts "Enter 'file:line' to query type info (e.g., 'app/models/user.rb:20')"
puts "Enter 'class#method' to query method info (e.g., 'User#full_name')"
puts "Enter 'q' to quit"
puts

loop do
  print "> "
  input = $stdin.gets&.strip
  break if input.nil? || input == "q"

  case input
  when /^(.+)#(.+)$/
    # クラス#メソッド クエリ
    class_name, method_name = $1, $2
    method_info = world.resolve_method(class_name, method_name)
    if method_info
      puts "  #{class_name}##{method_name}"
      puts "  owner: #{method_info.owner}"
      puts "  parameters: #{method_info.parameters.inspect}"
      puts "  location: #{method_info.source_location&.join(':')}"
    else
      puts "  (not found)"
    end

  when /^(.+):(\d+)$/
    # ファイル:行番号 クエリ
    file_pattern, line = $1, $2.to_i
    matches = inferrer.type_map.select do |key, info|
      info.file.include?(file_pattern) && info.line == line
    end
    if matches.any?
      matches.each do |key, info|
        puts "  #{info.expression}  → #{info.type || '(unknown)'}"
      end
    else
      puts "  (no type info at this location)"
    end

  else
    puts "  Format: 'Class#method' or 'file:line'"
  end
end
