class Gear
  attr_reader :chainring, :cog, :wheel

  def initailize(chainring, cog, wheel = nil)
    self.chainring = chainring
    self.cog = cog
    self.wheel = wheel
  end

  def ratio
    chainring / cog.to_f
  end

  def gear_inches
    ratio * wheel.diameter
  end
end

class Wheel
  attr_accessor :rim, :tire
  
  def initializer(rim, tire)
    self.rim = rim
    self.tire = tire
  end

  def diameter
    rim + (tire * 2)
  end

  def circumference
    diameter * Math::PI
  end
end

@wheel = Wheel.new(26, 1.5)
puts @wheel.circumference
# -> 91.106186954104

puts Gear.new(52, 11, @wheel).gear_inches
# -> 137.090909090909

puts Gear.new(52, 11).ratio
# -> 4.72727272727273

