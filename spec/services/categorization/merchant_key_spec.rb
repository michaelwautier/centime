require "rails_helper"

RSpec.describe Categorization::MerchantKey do
  {
    "CARREFOUR CITY 3407 PARIS 09/07" => "carrefour city paris",
    "CB CARREFOUR MARKET 12/2026" => "carrefour market",
    "PRLV SEPA Netflix.com" => "netflix com",
    "SNCF INTERNET" => "sncf internet",
    "VIR M WAUTIER" => "m wautier",
    "  Spotify AB  " => "spotify ab",
    "12345" => nil,
    "" => nil
  }.each do |input, expected|
    it "normalizes #{input.inspect} to #{expected.inspect}" do
      expect(described_class.from_text(input)).to eq(expected)
    end
  end

  it "prefers the merchant name over the description" do
    transaction = build(:transaction, merchant_name: "AMAZON EU", description: "ORDER 123-456")

    expect(described_class.for(transaction)).to eq("amazon eu")
  end
end
