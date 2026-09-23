require "json"
require_relative "../jev-cjk/jev"

# Asks about many specs in one request: the state holds one source file and a pack of spec files,
# with one question per spec. This is what a real selector would do, since one request per pair
# costs as many requests as the suite has spec files.
class PackedOracle
  # Jev rejects a state above 32k tokens; Ruby code runs at about 3.4 characters a token.
  CHAR_BUDGET = 90_000
  THREAD_COUNT = 6

  Ranking = Data.define(:scores, :positions, :calls, :input_tokens, :seconds)

  def initialize(dependency_map:, pack_size:)
    @dependency_map = dependency_map
    @pack_size = pack_size
    @cache_path = File.join(__dir__, "results/mastodon_jev_packed_#{pack_size}.json")
    @cache = File.exist?(@cache_path) ? JSON.parse(File.read(@cache_path)) : {}
    @clients = Array.new(THREAD_COUNT) { Jev.from_dotenv(path: File.join(__dir__, "../jev-cjk/.env")) }
  end

  # Specs are packed in the order given.
  def rank(source_path, test_paths)
    unless @cache.key?(source_path)
      @cache[source_path] = ask(source_path, test_paths).to_h.transform_keys(&:to_s)
      File.write(@cache_path, JSON.generate(@cache))
    end

    Ranking.new(**@cache.fetch(source_path).transform_keys(&:to_sym))
  end

  private

  def ask(source_path, test_paths)
    queue = Queue.new
    packs_of(source_path, test_paths).each { |pack| queue << pack }
    queue.close
    calls = queue.size
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    results = @clients.map do |jev|
      Thread.new do
        answered = []
        while (pack = queue.pop)
          answered << [pack, ask_pack(jev, source_path, pack)]
        end
        answered
      end
    end.flat_map(&:value)

    Ranking.new(
      scores: results.flat_map { |pack, result| pack.each_with_index.map { |test_path, index| [test_path, result.answers.fetch("spec_#{index}").fetch("noul")] } }.to_h,
      positions: results.flat_map { |pack, _| pack.each_with_index.map { |test_path, index| [test_path, index.fdiv(pack.size)] } }.to_h,
      calls:,
      input_tokens: results.sum { |_, result| result.usage.fetch("input_tokens") },
      seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    )
  end

  def ask_pack(jev, source_path, pack)
    state = {
      source_path:, source_code: @dependency_map.read(source_path),
      test_files: pack.map { |test_path| {path: test_path, code: @dependency_map.read(test_path)} }
    }
    questions = pack.each_with_index.to_h do |test_path, index|
      ["spec_#{index}", Jev.noul("Running the RSpec test file #{test_path} executes code defined in the source file #{source_path}.")]
    end
    jev.ask(state:, questions:)
  end

  def packs_of(source_path, test_paths)
    source_chars = @dependency_map.read(source_path).size
    test_paths.each_with_object([[]]) do |test_path, packs|
      pack_chars = source_chars + packs.last.sum { |packed_path| @dependency_map.read(packed_path).size }
      packs << [] if packs.last.size == @pack_size || (packs.last.any? && pack_chars + @dependency_map.read(test_path).size > CHAR_BUDGET)
      packs.last << test_path
    end
  end
end
