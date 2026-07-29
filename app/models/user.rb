class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  pay_customer default_payment_processor: :stripe

  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :bank_connections, dependent: :destroy
  has_many :bank_accounts, through: :bank_connections
  has_many :categorization_rules, dependent: :destroy
  has_many :merchant_category_mappings, dependent: :destroy
  has_many :bayes_tokens, dependent: :destroy
  has_many :bayes_category_stats, dependent: :destroy
end
