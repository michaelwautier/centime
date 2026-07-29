require "rails_helper"

RSpec.describe Categorization::LearnFromCorrection do
  let(:user) { create(:user) }
  let(:groceries) { create(:category, user: user, name: "Groceries") }
  let(:dining) { create(:category, user: user, name: "Dining") }

  let(:transaction) { create(:transaction, user: user, merchant_name: "CARREFOUR CITY 34") }

  it "learns the merchant mapping and token counts" do
    described_class.call(transaction: transaction, category: groceries)

    mapping = user.merchant_category_mappings.sole
    expect(mapping.merchant_key).to eq("carrefour city")
    expect(mapping.category).to eq(groceries)
    expect(user.bayes_category_stats.find_by(category: groceries).document_count).to eq(1)
    expect(user.bayes_tokens.where(category: groceries).pluck(:token)).to include("carrefour", "city")
  end

  it "increments the hit count on agreement" do
    2.times { described_class.call(transaction: transaction, category: groceries) }

    expect(user.merchant_category_mappings.sole.hit_count).to eq(2)
  end

  it "repoints the mapping and unlearns counts on correction" do
    described_class.call(transaction: transaction, category: groceries)
    described_class.call(transaction: transaction, category: dining, previous_category: groceries)

    expect(user.merchant_category_mappings.sole.category).to eq(dining)
    expect(user.bayes_category_stats.find_by(category: groceries).document_count).to eq(0)
    expect(user.bayes_category_stats.find_by(category: dining).document_count).to eq(1)
    expect(user.bayes_tokens.find_by(category: groceries, token: "carrefour").count).to eq(0)
  end

  it "does nothing without a category" do
    described_class.call(transaction: transaction, category: nil)

    expect(user.merchant_category_mappings).to be_empty
  end
end
