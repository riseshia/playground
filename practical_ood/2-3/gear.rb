class Gear
  attr_reader :chainring, :cog, :wheel

  def initailize(chainring, cog, rim, tire)
    self.chainring = chainring
    self.cog = cog
    self.wheel = Wheel.new(rim, tire)
  end

  def ratio
    chainring / cog.to_f
  end

  def gear_inches
    ratio * wheel.diameter
  end


  Wheel = Struct.new(:rim, :tire) do
    def diameter
      rim + (tire * 2)
    end
  end
end

# puts Gear.new(52, 11).ratio
# puts Gear.new(30, 27).ratio
