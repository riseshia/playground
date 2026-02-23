# メモリ・CPUプロファイル: 各操作のアロケーション数とCPU時間を計測する
require_relative "ruby_struct"
require "benchmark"

RS1 = RubyStruct.new(:a)
RS4 = RubyStruct.new(:a, :b, :c, :d)
RS8 = RubyStruct.new(:a, :b, :c, :d, :e, :f, :g, :h)

RS1_KW = RubyStruct.new(:a, keyword_init: true)
RS4_KW = RubyStruct.new(:a, :b, :c, :d, keyword_init: true)
RS8_KW = RubyStruct.new(:a, :b, :c, :d, :e, :f, :g, :h, keyword_init: true)

obj4   = RS4.new(1, 2, 3, 4)
obj4b  = RS4.new(1, 2, 3, 4)
obj8   = RS8.new(1, 2, 3, 4, 5, 6, 7, 8)

N_ALLOC = 1000
N_CPU   = 100_000

# --- メモリプロファイル: 1回あたりのオブジェクト生成数を計測 ---
def measure_allocs(label, n: N_ALLOC)
  3.times { yield } # ウォームアップ
  GC.start
  GC.disable
  before = GC.stat(:total_allocated_objects)
  n.times { yield }
  after = GC.stat(:total_allocated_objects)
  GC.enable
  allocs = after - before
  per_call = allocs.to_f / n
  printf "  %-35s %6d allocs / %d calls  (%5.2f / call)\n", label, allocs, n, per_call
end

# --- CPUプロファイル: 1回あたりのCPU時間(us)を計測 ---
def measure_cpu(label, n: N_CPU)
  3.times { yield } # ウォームアップ
  GC.start
  GC.disable
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  n.times { yield }
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
  GC.enable
  us_per_call = (elapsed / n) * 1_000_000
  printf "  %-35s %10.3f us/call  (%.4f s total, %d calls)\n", label, us_per_call, elapsed, n
end

# --- GCプロファイル: 大量呼び出し時のGC発生回数を計測 ---
def measure_gc_pressure(label, n: 100_000)
  3.times { yield } # ウォームアップ
  GC.start
  before_count = GC.stat(:count)
  before_time  = GC.stat(:time) rescue 0 # time は Ruby 3.1+ でミリ秒
  n.times { yield }
  after_count = GC.stat(:count)
  after_time  = GC.stat(:time) rescue 0
  gc_runs = after_count - before_count
  gc_time_ms = after_time - before_time
  printf "  %-35s %4d GC runs  (%d ms GC time, %d calls)\n", label, gc_runs, gc_time_ms, n
end

# === メモリプロファイル (アロケーション) ===
puts "=== メモリプロファイル: アロケーション (#{N_ALLOC} calls each) ==="

puts ""
puts "--- インスタンス生成 ---"
measure_allocs("new 1-field (positional)") { RS1.new(1) }
measure_allocs("new 4-field (positional)") { RS4.new(1, 2, 3, 4) }
measure_allocs("new 8-field (positional)") { RS8.new(1, 2, 3, 4, 5, 6, 7, 8) }
measure_allocs("new 1-field (keyword)")    { RS1_KW.new(a: 1) }
measure_allocs("new 4-field (keyword)")    { RS4_KW.new(a: 1, b: 2, c: 3, d: 4) }
measure_allocs("new 8-field (keyword)")    { RS8_KW.new(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8) }

puts ""
puts "--- アクセサ ---"
measure_allocs("getter (4-field)")    { obj4.a; obj4.b; obj4.c; obj4.d }
measure_allocs("[] symbol (4-field)") { obj4[:a]; obj4[:b]; obj4[:c]; obj4[:d] }
measure_allocs("[] index (4-field)")  { obj4[0]; obj4[1]; obj4[2]; obj4[3] }
measure_allocs("setter (4-field)")    { obj4.a = 1; obj4.b = 2; obj4.c = 3; obj4.d = 4 }
measure_allocs("[]= symbol (4-field)"){ obj4[:a] = 1; obj4[:b] = 2; obj4[:c] = 3; obj4[:d] = 4 }
measure_allocs("[]= index (4-field)") { obj4[0] = 1; obj4[1] = 2; obj4[2] = 3; obj4[3] = 4 }

puts ""
puts "--- 変換 ---"
measure_allocs("to_a (4-field)") { obj4.to_a }
measure_allocs("to_h (4-field)") { obj4.to_h }
measure_allocs("to_a (8-field)") { obj8.to_a }
measure_allocs("to_h (8-field)") { obj8.to_h }

puts ""
puts "--- 比較 ---"
measure_allocs("== (4-field)")   { obj4 == obj4b }
measure_allocs("eql? (4-field)") { obj4.eql?(obj4b) }
measure_allocs("hash (4-field)") { obj4.hash }

puts ""
puts "--- イテレーション ---"
measure_allocs("each (4-field)")      { obj4.each { |v| v } }
measure_allocs("each_pair (4-field)") { obj4.each_pair { |k, v| v } }

puts ""
puts "--- その他 ---"
measure_allocs("inspect (4-field)")   { obj4.inspect }
measure_allocs("members (4-field)")   { obj4.members }
measure_allocs("dig (4-field)")       { obj4.dig(:a) }
measure_allocs("values_at (4-field)") { obj4.values_at(0, 2) }

# === CPUプロファイル ===
puts ""
puts "=== CPUプロファイル (#{N_CPU} calls each) ==="

puts ""
puts "--- インスタンス生成 ---"
measure_cpu("new 1-field (positional)") { RS1.new(1) }
measure_cpu("new 4-field (positional)") { RS4.new(1, 2, 3, 4) }
measure_cpu("new 8-field (positional)") { RS8.new(1, 2, 3, 4, 5, 6, 7, 8) }
measure_cpu("new 1-field (keyword)")    { RS1_KW.new(a: 1) }
measure_cpu("new 4-field (keyword)")    { RS4_KW.new(a: 1, b: 2, c: 3, d: 4) }
measure_cpu("new 8-field (keyword)")    { RS8_KW.new(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8) }

puts ""
puts "--- アクセサ ---"
measure_cpu("getter (4-field)")    { obj4.a; obj4.b; obj4.c; obj4.d }
measure_cpu("[] symbol (4-field)") { obj4[:a]; obj4[:b]; obj4[:c]; obj4[:d] }
measure_cpu("[] index (4-field)")  { obj4[0]; obj4[1]; obj4[2]; obj4[3] }
measure_cpu("setter (4-field)")    { obj4.a = 1; obj4.b = 2; obj4.c = 3; obj4.d = 4 }

puts ""
puts "--- 変換 ---"
measure_cpu("to_a (4-field)") { obj4.to_a }
measure_cpu("to_h (4-field)") { obj4.to_h }

puts ""
puts "--- 比較 ---"
measure_cpu("== (4-field)")   { obj4 == obj4b }
measure_cpu("eql? (4-field)") { obj4.eql?(obj4b) }
measure_cpu("hash (4-field)") { obj4.hash }

puts ""
puts "--- イテレーション ---"
measure_cpu("each (4-field)")      { obj4.each { |v| v } }
measure_cpu("each_pair (4-field)") { obj4.each_pair { |k, v| v } }

puts ""
puts "--- その他 ---"
measure_cpu("inspect (4-field)")   { obj4.inspect }
measure_cpu("members (4-field)")   { obj4.members }

# === GC圧力プロファイル ===
puts ""
puts "=== GC圧力プロファイル (100000 calls each) ==="
measure_gc_pressure("new 4-field (positional)") { RS4.new(1, 2, 3, 4) }
measure_gc_pressure("new 4-field (keyword)")    { RS4_KW.new(a: 1, b: 2, c: 3, d: 4) }
measure_gc_pressure("to_a (4-field)")           { obj4.to_a }
measure_gc_pressure("to_h (4-field)")           { obj4.to_h }
measure_gc_pressure("inspect (4-field)")        { obj4.inspect }
measure_gc_pressure("hash (4-field)")           { obj4.hash }
