# http://www.codewars.com/kata/52996b5c99fdcb5f20000004/solutions/ruby

def transform(voters)
  voters.group_by { |voter| voter.first }.
         map { |who, list| [who, list.size] }.
         sort_by { |voter| -voter.last }
end

def get_first(list)
  if list[0][1] != list[1][1]
    list[0][0]
  else
    nil
  end
end

def remove_least(voters, list)
  last = list.last
  keys = list.select { |row| row[1] == last[1] }.
              flat_map { |row| row[0] }
  voters.map do |voter|
    voter.reject { |name| keys.include?(name) }
  end
end

def runoff(voters)
  return nil if voters.all?(&:empty?)
  list = transform(voters)
  first_rank = get_first(list)
  
  if first_rank.nil?
    runoff(remove_least(voters, list))
  else
    first_rank
  end
end

voters = [
  [:a, :c, :d, :e, :b],
  [:e, :b, :d, :c, :a],
  [:d, :e, :c, :a, :b],
  [:c, :e, :d, :b, :a],
  [:b, :e, :a, :c, :d]]

# voters = [[:dem, :ind, :rep],
#           [:rep, :ind, :dem],
#           [:ind, :dem, :rep],
#           [:ind, :rep, :dem]]

# voters = [[:dem, :ind, :rep],
#           [:dem, :ind, :rep],
#           [:ind, :dem, :rep],
#           [:ind, :rep, :dem],
#           [:rep, :dem, :ind]]

def assert_equals(actual, expected)
  if actual == expected
    puts "pass"
  else
    puts "fail"
  end
end

# assert_equals(runoff(voters), :ind)
assert_equals(runoff(voters), :dem)

