require 'prime'

pipe = Ractor.new do
  loop do
    Ractor.yield Ractor.receive
  end
end

N = 1000
RN = 10
workers = (1..RN).map do
  Ractor.new pipe do |pipe|
    while n = pipe.take
      Ractor.yield [n, n.prime?]
    end
  end
end

(1..N).each{|i|
  pipe << i
}

pp (1..N).map{
  _r, (n, b) = Ractor.select(*workers)
  [n, b]
}.sort_by{|(n, b)| n}
