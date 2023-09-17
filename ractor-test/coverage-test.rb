# frozen-string-literal: true

require 'coverage'

Coverage.start

require_relative './some_ractor_lib'
r = Ractor.new do
  loop do
    v = Ractor.receive
    ret_v = C.new.hoge(v)

# XXX
# coverage-test.rb:14:in `result': ractor unsafe method called from not main ractor (Ractor::UnsafeError)
#     from coverage-test.rb:14:in `block (2 levels) in <main>'
#     from <internal:kernel>:187:in `loop'
#     from coverage-test.rb:9:in `block in <main>'
# <internal:ractor>:827:in `take': thrown by remote Ractor. (Ractor::RemoteError)
#     from coverage-test.rb:25:in `<main>'
    #
    # puts "in local ractor"
    # Coverage.result.each do |file, lines|
    #   if file.include?('some_ractor_lib')
    #     p lines
    #   end
    # end

    Ractor.yield ret_v
  end
end

r << 1
pp r.take

puts "in main ractor"
Coverage.result.each do |file, lines|
  if file.include?('some_ractor_lib')
    p lines
    # => actual: [1, 1, 0, nil, nil]
    # => expected: [1, 1, 1, nil, nil]
  end
end
