module Roman
  TABLE = {
    1_000 => "M",
      900 => "CM",
      500 => "D",
      400 => "CD",
      100 => "C",
       90 => "XC",
       50 => "L",
       40 => "XL",
       10 => "X",
        9 => "IX",
        5 => "V",
        4 => "IV",
        1 => "I"
  }

  module_function
  def convert(number)
    return "" if number.zero?
    row = TABLE.find { |k,v| number >= k}
    if row.nil?
      fail "Can't find proper row with #{number}"
    else
      row.last + convert(number - row.first)
    end
  end
end

def solution(number)
  Roman.convert(number)
end

def expect(actual, expected)
  if actual == expected
    print "."
  else
    puts "#{actual} is not equal to #{expected}."
  end
end

[
  [solution(1), "I"],
  [solution(4), "IV"],
  [solution(5), "V"],
  [solution(9), "IX"],
  [solution(10), "X"],
  [solution(40), "XL"],
  [solution(50), "L"],
  [solution(90), "XC"],
  [solution(100), "C"],
  [solution(400), "CD"],
  [solution(500), "D"],
  [solution(900), "CM"],
  [solution(1000), "M"],
  [solution(1954), "MCMLIV"],
  [solution(1990), "MCMXC"],
  [solution(2014), "MMXIV"]
].each do |row|
  expect(row.first, row.last)
end
puts
