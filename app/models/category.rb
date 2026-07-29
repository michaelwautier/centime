class Category < ApplicationRecord
  belongs_to :user, optional: true # system default templates have no user

  has_many :transactions, dependent: :nullify

  enum :kind, { income: "income", expense: "expense" }

  validates :name, presence: true, uniqueness: { scope: [ :user_id, :kind ] }
  validates :kind, presence: true
  validates :color, presence: true, format: { with: /\A#\h{6}\z/ }

  scope :system_defaults, -> { where(user_id: nil) }
  scope :active, -> { where(archived_at: nil) }
  scope :ordered, -> { order(:kind, :name) }

  def archived? = archived_at.present?
end
