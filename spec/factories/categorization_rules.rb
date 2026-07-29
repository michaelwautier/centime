FactoryBot.define do
  factory :categorization_rule do
    user
    category { association :category, user: user }
    matcher_type { "contains" }
    pattern { "carrefour" }
  end
end
