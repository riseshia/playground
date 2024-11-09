# frozen_string_literal: true

require 'faraday'
require 'json'

streamed = []

conn = Faraday.new('http://localhost:3000')
conn.get('/events') do |req|
  req.options.on_data = proc do |chunk, _overall_received_bytes, _env|
    next if chunk.start_with?("event:")

    json = JSON.parse(chunk.sub("data: ", ""))
    streamed << json
  end
end

pp streamed
