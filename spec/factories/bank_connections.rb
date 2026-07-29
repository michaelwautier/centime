FactoryBot.define do
  factory :bank_connection do
    user
    institution_id { "SANDBOXFINANCE_SFIN0000" }
    institution_name { "Sandbox Finance" }
    sequence(:reference) { |n| "ref-#{n}" }
    sequence(:requisition_id) { |n| "req-#{n}" }
    status { "linked" }
    consent_expires_at { 80.days.from_now }
  end
end
