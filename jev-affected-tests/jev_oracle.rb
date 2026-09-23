require "json"
require_relative "../jev-cjk/jev"

# Asks Jev whether a spec executes a source file, given only the text of the two files.
# Answers are kept on disk per pair, so every experiment scores the same pair with the same answer.
class JevOracle
  QUESTION = "Running this RSpec test file executes code defined in the source file."
  # Jev allows 1,200 requests a minute; a call takes about 0.3s.
  THREAD_COUNT = 6
  SAVE_EVERY = 200

  def initialize(dependency_map:, cache_path: File.join(__dir__, "results/mastodon_jev.json"))
    @dependency_map = dependency_map
    @cache_path = cache_path
    @answers = File.exist?(cache_path) ? JSON.parse(File.read(cache_path)) : {}
    @lock = Mutex.new
  end

  def score(pair) = @answers.fetch(pair.key)

  def scored?(pair) = @answers.key?(pair.key)

  def ask_missing(pairs)
    queue = Queue.new
    pairs.uniq(&:key).reject { |pair| @answers.key?(pair.key) }.each { |pair| queue << pair }
    queue.close

    Array.new(THREAD_COUNT) { Thread.new { drain(queue) } }.each(&:join)
    save
  end

  # Bypasses the cache, to measure how much Jev's answer moves between two identical requests.
  def ask_again(pair) = ask(repeat_client, pair)

  private

  def drain(queue)
    jev = new_client
    while (pair = queue.pop)
      value = ask(jev, pair)
      @lock.synchronize do
        @answers[pair.key] = value
        save if (@answers.size % SAVE_EVERY).zero?
      end
    end
  end

  def ask(jev, pair)
    state = {
      source_path: pair.source_path, source_code: @dependency_map.read(pair.source_path),
      test_path: pair.test_path, test_code: @dependency_map.read(pair.test_path)
    }
    jev.ask(state:, questions: {executes: Jev.noul(QUESTION)}).answers.fetch("executes").fetch("noul")
  end

  def repeat_client = @repeat_client ||= new_client

  def new_client = Jev.from_dotenv(path: File.join(__dir__, "../jev-cjk/.env"))

  def save = File.write(@cache_path, JSON.generate(@answers))
end
