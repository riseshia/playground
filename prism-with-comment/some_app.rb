# Description: This script extracts the comments from a Ruby file using Prism
# Usage: ruby extract_comment.rb

class SomeApp
  def initialize(
    name #:: String
  )
    @name = name
  end

  def name #:: String
    @name
  end

  def update_name(
    &block #:: Proc
  ) #:: String
    @name = block.call(@name)
  end
end
