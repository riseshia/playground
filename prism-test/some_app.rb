class SomeApp
  def initialize
  end

  def run
    # just inline
    hige({ a: 1, b: 2 })

    # args with multiple line
    hige({
      a: 1,
      b: 2,
    })

    # args with single line and block
    hige({ a: 1, b: 2 }) do
      puts 'hoge'
    end

    # args with multiple line and block
    hige({
      a: 1,
      b: 2,
    }) do
      puts 'hoge'
    end

    # with no ()
    # just inline
    hige 1, 2, 3

    # with no ()
    # args with multiple line
    hige 1, 2,
      3, 4

    # with no ()
    # args with single line and block
    hige 1, 2, 3, 4 do
      puts 'hoge'
    end

    # with no ()
    # args with multiple line and block
    hige 1, 2,
      3, 4 do
      puts 'hoge'
    end
  end

  def hige(*args)
    p args
  end
end

SomeApp.new.run
