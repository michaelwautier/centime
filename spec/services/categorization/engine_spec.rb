require "rails_helper"

RSpec.describe Categorization::Engine do
  let(:user) { create(:user) }
  let(:groceries) { create(:category, user: user, name: "Groceries") }
  let(:dining) { create(:category, user: user, name: "Dining") }

  def learn(category, text, times: 1)
    times.times do
      Categorization::LearnFromCorrection.call(
        transaction: build(:transaction, user: user, merchant_name: text), category: category
      )
    end
  end

  it "matches user rules first" do
    create(:categorization_rule, user: user, category: dining, pattern: "carrefour")
    learn(groceries, "carrefour market", times: 12) # merchant + bayes disagree with the rule

    result = described_class.call(build(:transaction, user: user, merchant_name: "CARREFOUR MARKET 99"))

    expect(result.category_id).to eq(dining.id)
    expect(result.source).to eq("rule")
  end

  it "falls back to the learned merchant mapping" do
    learn(groceries, "CARREFOUR MARKET 99")

    result = described_class.call(build(:transaction, user: user, merchant_name: "CARREFOUR MARKET 12"))

    expect(result.category_id).to eq(groceries.id)
    expect(result.source).to eq("merchant")
  end

  it "falls back to Bayes for unseen merchants with similar tokens" do
    learn(groceries, "carrefour market city", times: 6)
    learn(dining, "burger king paris", times: 6)

    result = described_class.call(build(:transaction, user: user, merchant_name: "market carrefour"))

    expect(result.source).to eq("merchant").or eq("bayes")
    expect(result.category_id).to eq(groceries.id)
  end

  it "returns none when nothing matches" do
    result = described_class.call(build(:transaction, user: user, merchant_name: "mystery shop"))

    expect(result.category_id).to be_nil
    expect(result.source).to eq("none")
  end

  it "never suggests an archived category" do
    learn(groceries, "carrefour market")
    groceries.update!(archived_at: Time.current)

    result = described_class.call(build(:transaction, user: user, merchant_name: "carrefour market"))

    expect(result.category_id).to be_nil
  end

  describe "#suggestion" do
    it "returns a below-threshold Bayes guess" do
      learn(groceries, "carrefour market", times: 3) # under MIN_DOCUMENTS

      suggestion = described_class.new(user).suggestion(build(:transaction, user: user, merchant_name: "carrefour city"))

      expect(suggestion).to eq(groceries.id)
    end
  end
end
