class MerchantCategoryMapping < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :merchant_key, presence: true, uniqueness: { scope: :user_id }
end
