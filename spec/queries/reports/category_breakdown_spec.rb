require "rails_helper"

RSpec.describe Reports::CategoryBreakdown do
  let(:user) { create(:user) }
  let(:month) { Date.new(2026, 7, 1) }

  it "splits per-category totals into expenses and incomes" do
    groceries = create(:category, user: user, name: "Groceries")
    salary = create(:category, user: user, name: "Salary", kind: "income")
    create(:transaction, user: user, category: groceries, amount_cents: -3_000, booked_on: month)
    create(:transaction, user: user, category: groceries, amount_cents: -1_000, booked_on: month)
    create(:transaction, user: user, category: salary, amount_cents: 200_000, booked_on: month)
    create(:transaction, user: user, amount_cents: -500, booked_on: month) # uncategorized

    breakdown = described_class.new(user, month: month)

    expect(breakdown.expenses.map { |r| [ r.category&.name, r.cents, r.count ] })
      .to eq([ [ "Groceries", -4_000, 2 ], [ nil, -500, 1 ] ])
    expect(breakdown.incomes.map { |r| [ r.category&.name, r.cents ] }).to eq([ [ "Salary", 200_000 ] ])
  end
end
