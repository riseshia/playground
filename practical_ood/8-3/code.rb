class Bicycle
  attr_reader :size, :parts

  def initialize(args={})
    @size = args[:size]
    @parts = args[:parts]
  end

  def spares
    parts.spares
  end
end

require "forwardable"
class Parts
  extend Forwardable
  def_delegators :@parts, :size, :each
  include Enumerable

  def initialize(parts)
    @parts = parts
  end

  def spares
    parts.select(&:needs_spare)
  end
end

class RoadBikeParts < Parts
  attr_reader :tape_color

  def post_initialize(args)
    @tape_color = args[:type_color]
  end

  def local_spare
    {tape_color: tape_color}
  end

  def default_tire_size
    '23'
  end
end

class MountainBikeParts < Parts
  attr_reader :front_shock, :rear_shock

  def post_initialize(args)
    @front_shock = args[:front_shock]
    @rear_shock = args[:rear_shock]
  end

  def local_spares
    {rear_shock: rear_shock}
  end

  def default_tire_size
    '2.1'
  end
end

require "ostruct"
module PartsFactory
  def self.build(config,
                 parts_class = Parts)

    parts_class.new(
      config.collect { |part_config|
        OpenStruct.new(
          name: part_config[0],
          description: part_config[1],
          needs_spare: part_config.fetch(2, true))
      })
  end
end

config = [
  ["chain", "10-speed"],
  ["tire_size", "23"],
  ["type_color", "red"],
  ["tire_size", "2.1"],
  ["front_shock", "Manitou", false]]


