#!/usr/bin/env ruby
# Rails PoC: 実際の Rails アプリを起動して型情報を収集・表示する

require "prism"
require_relative "type_world"
require_relative "rails_world_builder"
require_relative "type_inferrer"

RAILS_ROOT = File.expand_path("../sample_app", __dir__)

# === Phase 1: Rails ブート + reflection で「世界」を構築 ===

puts "=== Phase 1: Booting Rails & Building Type World ==="
puts

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

builder = TypeGuess::RailsWorldBuilder.new
world = builder.build(rails_root: RAILS_ROOT)

t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Boot time: #{((t1 - t0) * 1000).round}ms"
puts

if builder.errors.any?
  puts "Errors:"
  builder.errors.each { |e| puts "  #{e}" }
  puts
end

# 世界の内容を表示
puts "--- Discovered Classes ---"
world.classes.each do |name, info|
  puts
  puts "#{name} < #{info.superclass}"
  puts "  ancestors: #{info.ancestors.first(5).join(' > ')}..."
  puts "  associations:"
  info.associations.each do |aname, ainfo|
    puts "    #{ainfo.macro} :#{aname} → #{ainfo.target_class}"
  end
  puts "  columns:"
  info.column_types.each do |cname, ctype|
    puts "    #{cname}: #{ctype}"
  end
  puts "  instance_methods(false): #{info.instance_methods.keys.sort.first(15).join(', ')}#{info.instance_methods.size > 15 ? '...' : ''}"
  puts "  singleton_methods(false): #{info.singleton_methods.keys.sort.first(10).join(', ')}"
end

# === Phase 2: AST 解析でメソッド本文の型推論 ===

puts
puts "=== Phase 2: Type Inference in Method Bodies ==="
puts

inferrer = TypeGuess::TypeInferrer.new(world)

model_files = Dir.glob(File.join(RAILS_ROOT, "app", "models", "*.rb"))
model_files.each do |file|
  inferrer.analyze_file(file)
end

# メソッド本文内の型情報を表示
puts "--- Local Variable Types in Method Bodies ---"
puts

inferrer.type_map.each do |key, info|
  next unless info.type
  short_file = info.file.sub(RAILS_ROOT + "/", "")
  # メソッド本文内の情報に絞る（クラスレベル DSL 呼び出しは除外）
  printf "  %-45s  %-40s  → %s\n", "#{short_file}:#{info.line}:#{info.column}", info.expression[0..39], info.type
end

# === 対話的クエリ ===

puts
puts "=== Query Mode ==="
puts "  'file:line'     → type info at location"
puts "  'Class#method'  → method info"
puts "  'Class.columns' → column types"
puts "  'Class.assoc'   → associations"
puts "  'q'             → quit"
puts

loop do
  print "> "
  input = $stdin.gets&.strip
  break if input.nil? || input == "q"

  case input
  when /^(.+)\.columns$/
    class_name = $1
    info = world.class_info(class_name)
    if info&.column_types&.any?
      info.column_types.each { |n, t| puts "  #{n}: #{t}" }
    else
      puts "  (no column info)"
    end

  when /^(.+)\.assoc$/
    class_name = $1
    info = world.class_info(class_name)
    if info&.associations&.any?
      info.associations.each { |n, a| puts "  #{a.macro} :#{n} → #{a.target_class}" }
    else
      puts "  (no associations)"
    end

  when /^(.+)#(.+)$/
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
    puts "  Format: 'Class#method', 'file:line', 'Class.columns', 'Class.assoc'"
  end
end
