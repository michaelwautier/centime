require "rails_helper"

RSpec.describe TransactionForm do
  let(:user) { create(:user) }

  it "stores expenses as negative cents" do
    form = described_class.new(user: user, amount: "12.34", direction: "expense", booked_on: Date.current)

    expect(form.save).to be(true)
    expect(form.transaction.amount_cents).to eq(-1234)
    expect(form.transaction.currency).to eq("EUR")
  end

  it "stores income as positive cents" do
    form = described_class.new(user: user, amount: "1500", direction: "income", booked_on: Date.current)

    expect(form.save).to be(true)
    expect(form.transaction.amount_cents).to eq(150_000)
  end

  it "marks the categorization as manual when a category is chosen" do
    category = create(:category, user: user)
    form = described_class.new(user: user, amount: "5", direction: "expense", category_id: category.id)

    expect(form.save).to be(true)
    expect(form.transaction).to be_categorized_by_manual
  end

  it "rejects zero and negative amounts" do
    expect(described_class.new(user: user, amount: "0").save).to be(false)
    expect(described_class.new(user: user, amount: "-3").save).to be(false)
  end

  it "rejects a category belonging to another user" do
    other_category = create(:category)
    form = described_class.new(user: user, amount: "5", category_id: other_category.id)

    expect(form.save).to be(false)
    expect(form.errors[:category_id]).to be_present
  end

  it "round-trips an existing expense for editing" do
    transaction = create(:transaction, user: user, amount_cents: -990)
    form = described_class.new(user: user, transaction: transaction)

    expect(form.amount).to eq(9.9)
    expect(form.direction).to eq("expense")
  end
end
