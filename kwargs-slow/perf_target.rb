# frozen_string_literal: true
# ruby perf_target.rb [class_pos|class_kw|struct_pos|struct_kw|data]

N = 20_000_000

class LocClassPos
  def initialize(offset) = @offset = offset
end

class LocClassKw
  def initialize(offset:) = @offset = offset
end

LocStructPos = Struct.new(:offset)
LocStructKw  = Struct.new(:offset, keyword_init: true)
LocData      = Data.define(:offset)

mode = ARGV[0] || "class_pos"

case mode
when "class_pos"
  N.times { |i| LocClassPos.new(i) }
when "class_kw"
  N.times { |i| LocClassKw.new(offset: i) }
when "struct_pos"
  N.times { |i| LocStructPos.new(i) }
when "struct_kw"
  N.times { |i| LocStructKw.new(offset: i) }
when "data"
  N.times { |i| LocData.new(offset: i) }
else
  abort "Usage: ruby perf_target.rb [class_pos|class_kw|struct_pos|struct_kw|data]"
end
