class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user

  validates :body, presence: true

  def preview
    text = body
    text ? text[0..50] : ""
  end

  def authored_by?(target_user)
    user == target_user
  end
end
