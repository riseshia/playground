require "minitest"

def tail(array)
  array[1..-1]
end

def factorial(number)
  (1..number).inject(&:*)
end

def calculate(chars, result = 0)
  return 0 if chars.size == 1
  targets = chars.sort

  if chars.first == targets.first
    result + calculate(tail(chars), result)
  else
    result + differ(chars, targets) + calculate(tail(chars), result)
  end
end

def differ(chars, targets)
  uniq_targets = targets.uniq
  ch_index = uniq_targets.index(chars.first)

  (0...ch_index).map do |idx|
    temp = targets.dup
    real_index = temp.index(uniq_targets[idx])

    temp.delete_at(real_index)
    full_differ(temp)
  end.inject(&:+)
end

def full_differ(chars)
  chars.map.with_index { |c, idx| idx + 1 }.inject(&:*) /
    chars.group_by { |i| i }.map { |_, v| factorial(v.size) }.inject(&:*)
end

def listPosition(word)
  calculate(word.split("")) + 1
end

def assert_equals actual, expected, message
  if actual != expected
    puts message
  else
    print "."
  end
end

testValues = {
  "A" => 1,
  "ABAB" => 2,
  "AAAB" => 1,
  "BAAA" => 4,
  "QUESTION" => 24572,
  "BOOKKEEPER" => 10743
}
testValues.each do |key,value|
  actual = listPosition(key)
  assert_equals(actual, value, "Incorrect list position for: " + key + ", actual: #{actual}")
end
