class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments

  scope :published, -> { where(status: "published") }
  scope :draft, -> { where(status: "draft") }

  validates :title, presence: true

  def published?
    status == "published"
  end

  def summary(length = 100)
    text = body
    if text.nil?
      ""
    else
      text[0...length]
    end
  end

  def author_name
    author = user
    if author
      author.name
    else
      "Unknown"
    end
  end

  def add_comment(commenter, text)
    comment = comments.create(user: commenter, body: text)
    comment
  end
end
