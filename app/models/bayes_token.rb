class BayesToken < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :token, presence: true, uniqueness: { scope: [ :user_id, :category_id ] }
end
