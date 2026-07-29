FactoryBot.define do
  factory :category do
    user
    sequence(:name) { |n| "Category #{n}" }
    kind { "expense" }
    color { "#6b7280" }

    trait :income do
      kind { "income" }
    end

    trait :system_default do
      user { nil }
    end

    trait :archived do
      archived_at { Time.current }
    end
  end
end
