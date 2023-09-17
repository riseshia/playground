# frozen_string_literal: true

# iv of Class test

# class C
#   @iv = 1
# end
#
# r = Ractor.new do
#   class C
#     @iv
#   end
# end
#
# p r.take #=> 1

# XXX: Fail to compile....?
# <internal:ractor>:275:in `new': must be called with a block (ArgumentError)
#         from shareable-test.rb:9:in `<main>'
# START
# class C
#   @iv = 1
# end
#
# p Ractor.new do
#   class C
#      @iv
#   end
# end.take #=> 1
# END

# Const test
# class C
#   CONST = 'str'.freeze
# end
#
# r = Ractor.new do
#   C::CONST = 2 # XXX: no response...
# end
#
# begin
#   pp r.take
# rescue => e
#   e.class #=> Ractor::IsolationError
# end

# Class variable
class C
  @@cv = 1
end

r = Ractor.new do
  class C
    p @@cv
  end
end

begin
  r.take
rescue => e
  e.class #=> Ractor::IsolationError
end
