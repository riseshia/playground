# frozen_string_literal: true

class HighCpuApp
  CHARS = ('a'..'z').map(&:freeze).freeze

  def call(_env)
    # this is SLOWER with ractors
    # 1000.times do |i|
    #   500.downto(1) do |j|
    #     Math.sqrt(j) * i / 0.2
    #   end
    # end

    3000.times do |i|
      Math.sqrt(23467**2436) * i / 0.2
    end

    [200, { "Content-Type" => "text/html" }, ["42"]]
  end
end
