# Builds a Transaction from user-facing input: a positive amount plus an
# income/expense direction, converted to signed integer cents.
class TransactionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  DIRECTIONS = %w[income expense].freeze

  attribute :amount, :decimal
  attribute :direction, :string, default: "expense"
  attribute :booked_on, :date, default: -> { Date.current }
  attribute :description, :string
  attribute :merchant_name, :string
  attribute :category_id, :integer

  attr_reader :user, :transaction

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :booked_on, presence: true
  validate :category_belongs_to_user

  def initialize(user:, transaction: nil, **attributes)
    @user = user
    @transaction = transaction || user.transactions.new
    super(**attributes.presence || attributes_from(@transaction))
  end

  def save
    return false unless valid?

    previous_category = transaction.persisted? ? transaction.category : nil
    transaction.assign_attributes(
      amount_cents: signed_cents,
      currency: user.currency,
      booked_on: booked_on,
      description: description.presence,
      merchant_name: merchant_name.presence,
      category_id: category_id,
      categorization_source: category_id ? "manual" : "none"
    )
    transaction.save!
    if transaction.category.present? && transaction.category != previous_category
      CategorizationLearnJob.perform_later(transaction, transaction.category, previous_category)
    end
    true
  end

  def persisted? = transaction.persisted?
  def model_name = ActiveModel::Name.new(self.class, nil, "Transaction")
  def to_param = transaction.to_param

  private

  def signed_cents
    cents = (amount * 100).round
    direction == "expense" ? -cents : cents
  end

  def category_belongs_to_user
    return if category_id.blank?
    errors.add(:category_id, :invalid) unless user.categories.active.exists?(category_id)
  end

  def attributes_from(transaction)
    return {} unless transaction.persisted?

    {
      amount: transaction.amount.abs,
      direction: transaction.expense? ? "expense" : "income",
      booked_on: transaction.booked_on,
      description: transaction.description,
      merchant_name: transaction.merchant_name,
      category_id: transaction.category_id
    }
  end
end
