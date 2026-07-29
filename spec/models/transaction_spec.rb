require "rails_helper"

RSpec.describe Transaction do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:category).optional }
  it { is_expected.to validate_presence_of(:booked_on) }
  it { is_expected.to validate_numericality_of(:amount_cents).is_other_than(0) }

  describe "sign helpers" do
    it "treats negative cents as expense and positive as income" do
      expense = build(:transaction, amount_cents: -500)
      income = build(:transaction, amount_cents: 500)

      expect(expense).to be_expense
      expect(income).to be_income
    end
  end

  describe ".in_month" do
    it "returns only transactions booked within the month" do
      user = create(:user)
      inside = create(:transaction, user: user, booked_on: Date.new(2026, 7, 15))
      create(:transaction, user: user, booked_on: Date.new(2026, 6, 30))

      expect(user.transactions.in_month(Date.new(2026, 7, 1))).to contain_exactly(inside)
    end
  end

  describe ".incomes / .expenses" do
    it "splits by amount sign" do
      user = create(:user)
      expense = create(:transaction, user: user, amount_cents: -100)
      income = create(:transaction, user: user, amount_cents: 100)

      expect(user.transactions.expenses).to contain_exactly(expense)
      expect(user.transactions.incomes).to contain_exactly(income)
    end
  end

  describe "#display_name" do
    it "prefers merchant name, falls back to description" do
      expect(build(:transaction, merchant_name: "Carrefour", description: "card").display_name).to eq("Carrefour")
      expect(build(:transaction, merchant_name: nil, description: "card").display_name).to eq("card")
    end
  end
end
