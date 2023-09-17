# frozen-string-literal: true

class C
  def hoge(i)
    i
  end
end

r = Ractor.new do
  loop do
    v = Ractor.receive
    Ractor.yield C.new.hoge(v)
  end
end

r << 1
pp r.take

class C
  def hoge(i)
    i + 1
  end
end

r << 1
pp r.take
