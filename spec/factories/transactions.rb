FactoryBot.define do
  factory :transaction do
    user
    amount_cents { -1050 }
    currency { "EUR" }
    booked_on { Date.current }
    description { "Test purchase" }

    trait :income do
      amount_cents { 250_000 }
      description { "Salary" }
    end
  end
end
