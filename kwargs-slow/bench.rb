# frozen_string_literal: true
# gem install benchmark-ips && ruby bench.rb

require "benchmark/ips"
require "objspace"
require_relative "ruby_struct"

puts "Ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})"

# 型定義
LocData       = Data.define(:offset)
LocStructKw   = Struct.new(:offset, keyword_init: true)
LocStructPos  = Struct.new(:offset)
LocRubyStKw   = RubyStruct.new(:offset, keyword_init: true)
LocRubyStPos  = RubyStruct.new(:offset)

class LocClassPos
  attr_reader :offset
  def initialize(offset) = @offset = offset
end

class LocClassKw
  attr_reader :offset
  def initialize(offset:) = @offset = offset
end

CNData         = Data.define(:method, :receiver, :args, :block_params,
                             :block_body, :has_block, :called_methods, :loc)
CNStructKw     = Struct.new(:method, :receiver, :args, :block_params,
                            :block_body, :has_block, :called_methods, :loc,
                            keyword_init: true)
CNStructPos    = Struct.new(:method, :receiver, :args, :block_params,
                            :block_body, :has_block, :called_methods, :loc)
CNRubyStKw     = RubyStruct.new(:method, :receiver, :args, :block_params,
                                :block_body, :has_block, :called_methods, :loc,
                                keyword_init: true)
CNRubyStPos    = RubyStruct.new(:method, :receiver, :args, :block_params,
                                :block_body, :has_block, :called_methods, :loc)

class CNClassPos
  attr_reader :method, :receiver, :args, :block_params,
              :block_body, :has_block, :called_methods, :loc
  def initialize(method, receiver, args, block_params, block_body, has_block, called_methods, loc)
    @method = method; @receiver = receiver; @args = args; @block_params = block_params
    @block_body = block_body; @has_block = has_block; @called_methods = called_methods; @loc = loc
  end
end

class CNClassKw
  attr_reader :method, :receiver, :args, :block_params,
              :block_body, :has_block, :called_methods, :loc
  def initialize(method:, receiver:, args:, block_params:, block_body:, has_block:, called_methods:, loc:)
    @method = method; @receiver = receiver; @args = args; @block_params = block_params
    @block_body = block_body; @has_block = has_block; @called_methods = called_methods; @loc = loc
  end
end

cm = []
loc = LocData.new(offset: 0)

# 1. 単一オブジェクト生成
[
  ["Loc (1 field)", {
    "Data.define(kw)" => -> { LocData.new(offset: 42) },
    "Data.define(pos)" => -> { LocData.new(42) },
    "Struct(kw)"     => -> { LocStructKw.new(offset: 42) },
    "Struct(pos)"    => -> { LocStructPos.new(42) },
    "RubyStruct(kw)" => -> { LocRubyStKw.new(offset: 42) },
    "RubyStruct(pos)" => -> { LocRubyStPos.new(42) },
    "Class(pos)"     => -> { LocClassPos.new(42) },
    "Class(kw)"      => -> { LocClassKw.new(offset: 42) },
  }],
  ["CallNode (8 fields)", {
    "Data.define(kw)" => -> { CNData.new(method: :foo, receiver: nil, args: cm,
                             block_params: cm, block_body: nil, has_block: false,
                             called_methods: cm, loc: loc) },
    "Data.define(pos)" => -> { CNData.new(:foo, nil, cm, cm, nil, false, cm, loc) },
    "Struct(kw)"     => -> { CNStructKw.new(method: :foo, receiver: nil, args: cm,
                             block_params: cm, block_body: nil, has_block: false,
                             called_methods: cm, loc: loc) },
    "Struct(pos)"    => -> { CNStructPos.new(:foo, nil, cm, cm, nil, false, cm, loc) },
    "RubyStruct(kw)" => -> { CNRubyStKw.new(method: :foo, receiver: nil, args: cm,
                              block_params: cm, block_body: nil, has_block: false,
                              called_methods: cm, loc: loc) },
    "RubyStruct(pos)" => -> { CNRubyStPos.new(:foo, nil, cm, cm, nil, false, cm, loc) },
    "Class(pos)"     => -> { CNClassPos.new(:foo, nil, cm, cm, nil, false, cm, loc) },
    "Class(kw)"      => -> { CNClassKw.new(method: :foo, receiver: nil, args: cm,
                              block_params: cm, block_body: nil, has_block: false,
                              called_methods: cm, loc: loc) },
  }],
].each do |label, variants|
  puts "\n### #{label}"
  Benchmark.ips do |x|
    x.config(warmup: 2, time: 5)
    variants.each { |name, block| x.report(name, &block) }
    x.compare!
  end
end

# 2. バルク生成 (200万オブジェク)
puts "\n### Bulk: Loc 2M objects"
n = 2_000_000
{ "Data.define(kw)" => -> { Array.new(n) { |i| LocData.new(offset: i) } },
  "Data.define(pos)" => -> { Array.new(n) { |i| LocData.new(i) } },
  "Struct(pos)"    => -> { Array.new(n) { |i| LocStructPos.new(i) } },
  "RubyStruct(pos)" => -> { Array.new(n) { |i| LocRubyStPos.new(i) } },
  "Class(pos)"     => -> { Array.new(n) { |i| LocClassPos.new(i) } },
  "Class(kw)"      => -> { Array.new(n) { |i| LocClassKw.new(offset: i) } },
  "Integer"        => -> { Array.new(n) { |i| i } },
}.each do |label, block|
  3.times { GC.start(full_mark: true, immediate_sweep: true) }
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  block.call
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  printf "%-15s  %.3fs\n", label, t
end
