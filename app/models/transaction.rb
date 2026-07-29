class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  enum :source, { manual: "manual", bank_sync: "bank_sync" }, prefix: true
  enum :categorization_source,
       { manual: "manual", rule: "rule", merchant: "merchant", bayes: "bayes", none: "none" },
       prefix: :categorized_by

  validates :amount_cents, presence: true, numericality: { other_than: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :booked_on, presence: true

  scope :in_month, ->(date) { where(booked_on: date.beginning_of_month..date.end_of_month) }
  scope :incomes, -> { where(amount_cents: 1..) }
  scope :expenses, -> { where(amount_cents: ...0) }
  scope :recent_first, -> { order(booked_on: :desc, id: :desc) }
  scope :uncategorized, -> { where(category_id: nil) }

  def amount = amount_cents / 100.0
  def expense? = amount_cents.negative?
  def income? = amount_cents.positive?

  def display_name
    merchant_name.presence || description.presence || I18n.t("transactions.unnamed", default: "(no description)")
  end
end
