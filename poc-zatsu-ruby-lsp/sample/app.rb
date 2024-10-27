# frozen_string_literal: true

class App
  VERSON = '1.1.0'

  include SomeModule

  def self.run
    post = Post.find(1)

    post.format
  end
end
