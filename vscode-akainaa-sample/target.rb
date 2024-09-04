class Hoge
  def initialize
    @a = 1
  end

  def a
    @a
  end
end

hoge = Hoge.new

3.times { hoge.a }
