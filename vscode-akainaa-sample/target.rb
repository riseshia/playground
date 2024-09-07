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
5.times { hoge.a }
10.times { hoge.a }
20.times { hoge.a }
10.times { hoge.a }
5.times { hoge.a }
3.times { hoge.a }
1.times { hoge.a }