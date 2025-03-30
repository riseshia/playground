# Description: This script extracts the comments from a Ruby file using Prism
# Usage: ruby extract_comment.rb

require 'prism'

def extract_method_from_file(file_path)
  # Read the file content
  file_content = File.read(file_path)

  # Parse the file content using Prism
  parsed_content = Prism.parse(file_content)

  parsed_content.attach_comments!
  binding.irb
  pp parsed_content
  parsed_content.source.slice(0, 77)
end

extract_method_from_file('some_app.rb')
