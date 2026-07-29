require "rails_helper"

RSpec.describe User do
  it { is_expected.to have_many(:categories).dependent(:destroy) }
  it { is_expected.to have_many(:transactions).dependent(:destroy) }

  it "defaults to EUR currency" do
    expect(described_class.new.currency).to eq("EUR")
  end
end
