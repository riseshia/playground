require "json"
require "net/http"

class Jev
  ENDPOINT = URI("https://api.typesafe.ai/v1/systemone")
  # Pinned so that runs from different days stay comparable.
  MODEL = "jev-1.13.0"
  RETRYABLE_STATUSES = ["429", "529"].freeze

  class RequestFailed < StandardError; end

  Result = Data.define(:answers, :usage, :elapsed)

  def self.from_dotenv(path: File.join(__dir__, ".env"))
    api_key = File.read(path)[/^TYPESAFE_AI_API_KEY=(\S+)/, 1]
    raise ArgumentError, "TYPESAFE_AI_API_KEY is missing in #{path}" if api_key.nil?

    new(api_key:)
  end

  def initialize(api_key:)
    @api_key = api_key
  end

  def ask(state:, questions:, max_attempts: 5)
    request = Net::HTTP::Post.new(ENDPOINT)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(state:, model: MODEL, questions:)

    max_attempts.times do |attempt|
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = http.request(request)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

      if response.is_a?(Net::HTTPSuccess)
        body = JSON.parse(response.body)
        return Result.new(answers: body.fetch("answers"), usage: body.fetch("usage"), elapsed:)
      end
      raise RequestFailed, "#{response.code}: #{response.body}" unless RETRYABLE_STATUSES.include?(response.code)

      sleep(2**attempt)
    end

    raise RequestFailed, "still rate limited or overloaded after #{max_attempts} attempts"
  end

  def self.noul(instructions, criteria: nil)
    {type: "noul", instructions:, criteria:}.compact
  end

  def self.choice(instructions, criteria:)
    {type: "choice", instructions:, criteria:}
  end

  def self.score(instructions, criteria:)
    {type: "score", instructions:, criteria:}
  end

  private

  # One kept-alive connection, otherwise every latency figure is mostly TLS handshake.
  def http
    @http ||= Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true)
  end
end
