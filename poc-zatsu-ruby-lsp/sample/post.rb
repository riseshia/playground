class Post
  attr_reader :title, :body, :id

  def initialize(id, title, body)
    @id = id
    @title = title
    @body = body
  end

  def format
    @title + @body
  end

  def self.find(id)
    Post.new(id, 'title', 'body')
  end
end
