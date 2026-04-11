class User < ApplicationRecord
  has_many :posts
  has_many :comments
  has_many :published_posts, -> { where(status: "published") }, class_name: "Post"

  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }

  validates :name, presence: true
  validates :email, presence: true, format: { with: /@/ }

  def full_name
    name_str = name
    "User: #{name_str}"
  end

  def recent_posts(limit = 5)
    posts_list = posts
    posts_list.limit(limit)
  end

  def active_posts
    result = posts.where(status: "published")
    result
  end
end
