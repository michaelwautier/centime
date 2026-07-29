require "rails_helper"

RSpec.describe Categories::ProvisionDefaults do
  it "copies system default categories to the user" do
    create(:category, :system_default, name: "Groceries", kind: "expense", color: "#f59e0b")
    create(:category, :system_default, name: "Salary", kind: "income")
    user = create(:user)

    described_class.call(user: user)

    expect(user.categories.pluck(:name, :kind)).to contain_exactly([ "Groceries", "expense" ], [ "Salary", "income" ])
    expect(user.categories.find_by(name: "Groceries").color).to eq("#f59e0b")
  end

  it "is idempotent" do
    create(:category, :system_default, name: "Groceries")
    user = create(:user)

    2.times { described_class.call(user: user) }

    expect(user.categories.count).to eq(1)
  end
end
