# frozen_string_literal: true

class CpuHeavyApp
  CHARS = ('a'..'z').map(&:freeze).freeze

  def call(_env)
    res_body = ""
    # this is SLOWER with ractors
    10.times do |i|
      500.downto(1) do |j|
        Math.sqrt(j) * i / 0.2
      end
      sleep 0.01
      partial = 1000.times.map { CHARS.sample }.join
      res_body += partial
      res_body += "\n"
    end

    # 100.times do |i|
    #   Math.sqrt(23467**2436) * i / 0.2
    # end

    [200, { "Content-Type" => "text/html" }, [res_body]]
  end
end
