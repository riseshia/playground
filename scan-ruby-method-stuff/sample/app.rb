module SomeModule
  class Hoge
    def add_prefix(a)
      "prefix_" + a
    end
  end
end

hoge = Hoge.new
hoge.add_prefix("hoge")
