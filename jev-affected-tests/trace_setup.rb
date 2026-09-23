require "affected_tests"

AffectedTests.setup(
  engine: :coverage,
  project_path: Dir.pwd,
  test_dir_path: "spec/",
  output_path: ENV.fetch("AFFECTED_TESTS_MAP_PATH"),
  revision: `git rev-parse HEAD`.chomp
)

require "affected_tests/rspec"

RSpec.configure do |config|
  # Without this, a file counts as used by whichever spec happens to autoload it first,
  # so the labels would depend on the execution order.
  config.before(:suite) { Rails.application.eager_load! }
end
