# frozen-string-literal: true

require 'coverage'

Coverage.start

require_relative './some_ractor_lib'

r = Ractor.new do
  loop do
    v = Ractor.receive
    ret_v = C.new.hoge(v)

    Ractor.yield ret_v
  end
end

2.times do |i|
  r << i
  r.take
end

Coverage.result.each do |file, lines|
  if file.include?('some_ractor_lib')
    if lines == [1, 1, 2, nil, nil]
      puts "OK"
    else
      puts "expected: [1, 1, 2, nil, nil]"
      puts "actual: #{lines.inspect}"
    end
  end
end
