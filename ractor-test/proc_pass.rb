SomeStr = Struct.new(:a, :b, keyword_init: true)

module Callbacks
  module_function

  def callbacks
    @callbacks ||= {}.freeze
  end

  def fire(name)
    waiwai
    # p method(name.to_sym)
    # method(name.to_sym).call
  end

  def waiwai
    2
  end
end

Callbacks.define_singleton_method(:foo) do
  puts "before_callback"
end

Callbacks.callbacks

r = Ractor.new do
  p Ractor.receive

  Callbacks.fire('foo')
end

r << 1
r.take
