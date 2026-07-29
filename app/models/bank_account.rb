class BankAccount < ApplicationRecord
  belongs_to :bank_connection
  has_one :user, through: :bank_connection
  has_many :transactions, dependent: :nullify

  validates :gocardless_account_id, presence: true, uniqueness: true

  def display_name
    [ name.presence || "Account", iban_last4.presence && "····#{iban_last4}" ].compact.join(" ")
  end
end
