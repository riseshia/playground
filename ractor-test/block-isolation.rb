# https://github.com/ruby/ruby/blob/master/doc/ractor.md

# begin
#   a = true
#   r = Ractor.new do
#     a #=> ArgumentError because this block accesses `a`.
#   end
#   r.take # see later
# rescue ArgumentError
# end

# r = Ractor.new do
#   p self.class #=> Ractor
#   p self.object_id
#   self.object_id
# end
# rid = r.take
# p rid
# p self.object_id

# main_msg = "ok"
# puts "main_msg: #{main_msg.object_id}"
# r = Ractor.new main_msg do |msg|
#   puts "msg: #{msg.object_id}"
# end
# r.take

# <internal:ractor>:273:in `new': unknown keywords: :a, :b (ArgumentError)
# r = Ractor.new(a: 1, b: 2)do |msg|
#   puts "msg: #{msg.object_id}"
# end
# r.take

# r = Ractor.new do
#   msg = Ractor.receive
#   p msg #  OK
#   # pp msg # XXX: NG
#   # <internal:/.rbenv/versions/3.3.0-dev/lib/ruby/3.3.0+0/rubygems/core_ext/kernel_require.rb>:39:in `require': can not access non-shareable objects in constant Kernel::RUBYGEMS_ACTIVATION_MONITOR by non-main ractor. (Ractor::IsolationError)
#   #     from <internal:prelude>:14:in `pp'
#   #     from block-isolation.rb:36:in `block in <main>'
#
#   msg
# end
# r.send 'ok'
# r.take

# almost similar to the last example
r = Ractor.new do
  Ractor.yield '1'
  Ractor.yield '2'
  '3'
end
p r.take #=> '1'
p r.take #=> '2'
p r.take #=> '3'
