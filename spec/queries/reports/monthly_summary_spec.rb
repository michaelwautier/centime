require "rails_helper"

RSpec.describe Reports::MonthlySummary do
  let(:user) { create(:user) }
  let(:month) { Date.new(2026, 7, 1) }

  describe "#totals" do
    it "sums income and expenses for the month only" do
      create(:transaction, user: user, amount_cents: 250_000, booked_on: month + 4)
      create(:transaction, user: user, amount_cents: -10_000, booked_on: month + 10)
      create(:transaction, user: user, amount_cents: -5_000, booked_on: month - 1) # previous month

      totals = described_class.new(user, month: month).totals

      expect(totals.income_cents).to eq(250_000)
      expect(totals.expense_cents).to eq(10_000)
      expect(totals.net_cents).to eq(240_000)
    end

    it "returns zeros with no transactions" do
      totals = described_class.new(user, month: month).totals

      expect(totals.income_cents).to eq(0)
      expect(totals.expense_cents).to eq(0)
    end
  end

  describe "#expense_breakdown" do
    it "groups expense cents by category name, largest first, with uncategorized bucket" do
      groceries = create(:category, user: user, name: "Groceries")
      create(:transaction, user: user, category: groceries, amount_cents: -3_000, booked_on: month)
      create(:transaction, user: user, category: groceries, amount_cents: -2_000, booked_on: month)
      create(:transaction, user: user, amount_cents: -9_000, booked_on: month)
      create(:transaction, user: user, amount_cents: 100_000, booked_on: month) # income ignored

      breakdown = described_class.new(user, month: month).expense_breakdown

      expect(breakdown).to eq("Uncategorized" => 9_000, "Groceries" => 5_000)
      expect(breakdown.keys.first).to eq("Uncategorized")
    end
  end

  describe "#trend" do
    it "returns one entry per month including empty months" do
      create(:transaction, user: user, amount_cents: -1_000, booked_on: month - 2.months)
      create(:transaction, user: user, amount_cents: 4_000, booked_on: month + 3)

      trend = described_class.new(user, month: month).trend(months: 3)

      expect(trend.keys).to eq([ month - 2.months, month - 1.month, month ])
      expect(trend[month - 2.months]).to eq(income_cents: 0, expense_cents: 1_000)
      expect(trend[month - 1.month]).to eq(income_cents: 0, expense_cents: 0)
      expect(trend[month]).to eq(income_cents: 4_000, expense_cents: 0)
    end
  end
end
