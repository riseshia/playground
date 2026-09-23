require "fileutils"
require "json"
require "net/http"

# Reads rows through the Hugging Face datasets server, so no Python tooling is needed.
module HfDataset
  ROWS_ENDPOINT = "https://datasets-server.huggingface.co/rows"
  PAGE_SIZE = 100
  THROTTLE_WAIT_SECONDS = 60
  CACHE_DIR = File.join(__dir__, "data")

  def self.load_rows(dataset:, config:, split:, limit:)
    path = File.join(CACHE_DIR, dataset.tr("/", "_"), "#{config}-#{split}-#{limit}.json")
    return JSON.parse(File.read(path)) if File.exist?(path)

    rows = fetch_rows(dataset:, config:, split:, limit:)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.generate(rows))
    rows
  end

  def self.fetch_rows(dataset:, config:, split:, limit:)
    rows = []
    while rows.size < limit
      uri = URI(ROWS_ENDPOINT)
      uri.query = URI.encode_www_form(dataset:, config:, split:, offset: rows.size, length: [PAGE_SIZE, limit - rows.size].min)
      response = Net::HTTP.get_response(uri)
      # The datasets server throttles bursts; a page fetched a minute later succeeds.
      if response.code == "429"
        sleep(THROTTLE_WAIT_SECONDS)
        next
      end
      raise "#{dataset} #{config}/#{split}: #{response.code} #{response.body[0, 200]}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      rows.concat(body.fetch("rows").map { |row| row.fetch("row") })
      break if rows.size >= body.fetch("num_rows_total")
    end
    rows
  end
  private_class_method :fetch_rows
end
