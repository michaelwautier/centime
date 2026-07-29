require "rails_helper"

RSpec.describe Categorization::BayesClassifier do
  let(:user) { create(:user) }
  let(:groceries) { create(:category, user: user, name: "Groceries") }
  let(:transport) { create(:category, user: user, name: "Transport") }

  def train(category, text, times: 1)
    times.times do
      transaction = build(:transaction, user: user, merchant_name: text)
      Categorization::LearnFromCorrection.call(transaction: transaction, category: category)
    end
  end

  it "classifies confidently once trained on enough documents" do
    train(groceries, "carrefour market", times: 6)
    train(transport, "sncf tgv paris", times: 6)

    guess = described_class.new(user).classify(build(:transaction, user: user, merchant_name: "carrefour city"))

    expect(guess.category_id).to eq(groceries.id)
    expect(guess.confident).to be(true)
  end

  it "is not confident below the minimum corpus size" do
    train(groceries, "carrefour market", times: 3)

    guess = described_class.new(user).classify(build(:transaction, user: user, merchant_name: "carrefour city"))

    expect(guess.confident).to be(false)
  end

  it "is not confident when scores are too close" do
    train(groceries, "monoprix paris centre", times: 6)
    train(transport, "navigo paris centre", times: 6)

    guess = described_class.new(user).classify(build(:transaction, user: user, merchant_name: "paris centre"))

    expect(guess.confident).to be(false)
  end

  it "returns nil with no training data or no usable tokens" do
    classifier = described_class.new(user)

    expect(classifier.classify(build(:transaction, user: user, merchant_name: "carrefour"))).to be_nil

    train(groceries, "carrefour", times: 1)
    expect(
      described_class.new(user).classify(build(:transaction, user: user, merchant_name: "12 34", description: nil))
    ).to be_nil
  end
end
