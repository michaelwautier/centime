class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category

  enum :matcher_type, { contains: "contains", equals: "equals" }, prefix: :matcher

  validates :pattern, presence: true

  scope :ordered, -> { order(:position, :id) }

  def matches?(text)
    return false if text.blank?

    haystack = text.downcase
    needle = pattern.downcase
    matcher_equals? ? haystack == needle : haystack.include?(needle)
  end
end
