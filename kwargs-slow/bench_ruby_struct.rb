require "benchmark/ips"
require_relative "ruby_struct"

# 1フィールド / 4フィールド / 8フィールドの構造体を定義
RS1 = RubyStruct.new(:a)
RS4 = RubyStruct.new(:a, :b, :c, :d)
RS8 = RubyStruct.new(:a, :b, :c, :d, :e, :f, :g, :h)

RS1_KW = RubyStruct.new(:a, keyword_init: true)
RS4_KW = RubyStruct.new(:a, :b, :c, :d, keyword_init: true)
RS8_KW = RubyStruct.new(:a, :b, :c, :d, :e, :f, :g, :h, keyword_init: true)

puts "=== インスタンス生成 ==="
Benchmark.ips do |x|
  x.report("new 1-field") { RS1.new(1) }
  x.report("new 4-field") { RS4.new(1, 2, 3, 4) }
  x.report("new 8-field") { RS8.new(1, 2, 3, 4, 5, 6, 7, 8) }
  x.report("kw  1-field") { RS1_KW.new(a: 1) }
  x.report("kw  4-field") { RS4_KW.new(a: 1, b: 2, c: 3, d: 4) }
  x.report("kw  8-field") { RS8_KW.new(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8) }
  x.compare!
end

puts "\n=== ゲッター ==="
obj1 = RS4.new(1, 2, 3, 4)
Benchmark.ips do |x|
  x.report("getter")    { obj1.a; obj1.b; obj1.c; obj1.d }
  x.report("[] symbol") { obj1[:a]; obj1[:b]; obj1[:c]; obj1[:d] }
  x.report("[] index")  { obj1[0]; obj1[1]; obj1[2]; obj1[3] }
  x.compare!
end

puts "\n=== セッター ==="
Benchmark.ips do |x|
  x.report("setter")     { obj1.a = 1; obj1.b = 2; obj1.c = 3; obj1.d = 4 }
  x.report("[]= symbol") { obj1[:a] = 1; obj1[:b] = 2; obj1[:c] = 3; obj1[:d] = 4 }
  x.report("[]= index")  { obj1[0] = 1; obj1[1] = 2; obj1[2] = 3; obj1[3] = 4 }
  x.compare!
end

puts "\n=== 変換 ==="
Benchmark.ips do |x|
  x.report("to_a 4-field") { obj1.to_a }
  x.report("to_h 4-field") { obj1.to_h }
  x.compare!
end

puts "\n=== 等値比較 ==="
obj_a = RS4.new(1, 2, 3, 4)
obj_b = RS4.new(1, 2, 3, 4)
Benchmark.ips do |x|
  x.report("== 4-field")   { obj_a == obj_b }
  x.report("eql? 4-field") { obj_a.eql?(obj_b) }
  x.report("hash 4-field") { obj_a.hash }
  x.compare!
end

puts "\n=== イテレーション ==="
Benchmark.ips do |x|
  x.report("each 4-field")      { obj1.each { |v| v } }
  x.report("each_pair 4-field") { obj1.each_pair { |k, v| v } }
  x.compare!
end

puts "\n=== inspect ==="
Benchmark.ips do |x|
  x.report("inspect 4-field") { obj1.inspect }
  x.compare!
end
