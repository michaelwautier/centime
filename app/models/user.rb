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
end
