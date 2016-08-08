class Gear
  attr_reader :chainring, :cog

  def initailize(chainring, cog)
    self.chainring = chainring
    self.cog = cog
  end

  def ratio
    chainring / cog.to_f
  end
end

# puts Gear.new(52, 11).ratio
# puts Gear.new(30, 27).ratio
