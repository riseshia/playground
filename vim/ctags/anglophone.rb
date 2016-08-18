require './speaker.rb'
class Anglophone < Speaker
  def speak
    puts "Hello, my name is #{@name}"
  end
end

a = 1
b = 2
sum = a + b
Anglophone.new('Jack').speak
