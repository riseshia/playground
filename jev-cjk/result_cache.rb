require "fileutils"
require "json"

# Keeps each model's answers in their own file, so adding another baseline model
# reuses the Jev answers already collected instead of drawing new, slightly different ones.
module ResultCache
  DIR = File.join(__dir__, "results")

  def self.fetch(name)
    path = File.join(DIR, "#{name}.json")
    return JSON.parse(File.read(path)) if File.exist?(path)

    value = yield
    FileUtils.mkdir_p(DIR)
    File.write(path, JSON.generate(value))
    JSON.parse(File.read(path))
  end
end
