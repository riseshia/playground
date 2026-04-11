class Category < ApplicationRecord
  has_many :posts

  validates :name, presence: true

  def post_count
    count = posts.count
    count
  end
end
