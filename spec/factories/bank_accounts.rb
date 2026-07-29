FactoryBot.define do
  factory :bank_account do
    bank_connection
    sequence(:gocardless_account_id) { |n| "gc-account-#{n}" }
    name { "Current account" }
    iban_last4 { "1234" }
    currency { "EUR" }
  end
end
