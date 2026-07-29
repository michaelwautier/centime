# Idempotent seeds: system default categories (user_id: nil) copied to each
# new user by Categories::ProvisionDefaults at sign-up.
SYSTEM_CATEGORIES = {
  "income" => [
    [ "Salary", "#059669" ],
    [ "Freelance", "#10b981" ],
    [ "Interest", "#34d399" ]
  ],
  "expense" => [
    [ "Groceries", "#f59e0b" ],
    [ "Rent", "#6366f1" ],
    [ "Utilities", "#0ea5e9" ],
    [ "Transport", "#8b5cf6" ],
    [ "Dining", "#ef4444" ],
    [ "Health", "#14b8a6" ],
    [ "Entertainment", "#ec4899" ],
    [ "Shopping", "#f97316" ],
    [ "Fees", "#64748b" ],
    [ "Other", "#6b7280" ]
  ]
}.freeze

SYSTEM_CATEGORIES.each do |kind, entries|
  entries.each do |name, color|
    Category.system_defaults.find_or_create_by!(name: name, kind: kind) do |category|
      category.color = color
    end
  end
end
