class BayesCategoryStat < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :category_id, uniqueness: { scope: :user_id }
end
