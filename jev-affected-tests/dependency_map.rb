require "json"

# The answer key: which spec files executed which source files,
# recorded by affected_tests' coverage engine over a real run of the project's suite.
class DependencyMap
  PROJECT_PATH = File.expand_path("~/repos/mastodon/mastodon")
  MAP_PATH = File.join(__dir__, "results/mastodon-map.json")
  RSPEC_LOG_PATH = File.join(__dir__, "results/mastodon-rspec.log")
  UBIQUITOUS_SHARE = 0.5
  # Keeps the largest models plus their spec under Jev's 32k-token state limit.
  MAX_FILE_CHARS = 20_000

  attr_reader :tests_by_source, :sources_by_test

  def self.load
    map = JSON.parse(File.read(MAP_PATH)).fetch("map")
    # A spec that fails stops early, so "did not execute" is not trustworthy for it.
    failed_test_paths = File.read(RSPEC_LOG_PATH).scan(%r{^rspec \./(spec/\S+?_spec\.rb)}).flatten.uniq

    new(map:, failed_test_paths:)
  end

  def initialize(map:, failed_test_paths:)
    @tests_by_source = map
      .select { |source_path, _| source_path.end_with?(".rb") && source_path.start_with?("app/", "lib/") }
      .transform_values { |test_paths| test_paths.select { |test_path| test_path.end_with?("_spec.rb") } - failed_test_paths }
      .reject { |_, test_paths| test_paths.empty? }
    @sources_by_test = Hash.new { |hash, test_path| hash[test_path] = [] }
    @tests_by_source.each { |source_path, test_paths| test_paths.each { |test_path| @sources_by_test[test_path] << source_path } }
    @contents = {}
  end

  def source_paths = tests_by_source.keys.sort

  def test_paths = sources_by_test.keys.sort

  def executing_share(source_path) = tests_by_source.fetch(source_path).size.fdiv(sources_by_test.size)

  def ubiquitous?(source_path) = executing_share(source_path) >= UBIQUITOUS_SHARE

  def read(path)
    @contents[path] ||= File.read(File.join(PROJECT_PATH, path))[0, MAX_FILE_CHARS]
  end
end

Pair = Data.define(:test_path, :source_path, :executed) do
  def key = "#{test_path}|#{source_path}"

  def name_matched?
    File.basename(source_path, ".rb").delete_suffix("_controller") == File.basename(test_path, "_spec.rb").delete_suffix("_controller")
  end

  def constant_name = File.basename(source_path, ".rb").split("_").map(&:capitalize).join
end
