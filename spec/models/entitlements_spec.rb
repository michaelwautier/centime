require "rails_helper"

RSpec.describe Entitlements do
  let(:user) { create(:user) }

  def stub_pro(user, value)
    processor = instance_double(Pay::Customer, subscribed?: value)
    allow(user).to receive(:payment_processor).and_return(processor)
  end

  it "allows one bank connection on the free plan" do
    entitlements = described_class.new(user)

    expect(entitlements.pro?).to be(false)
    expect(entitlements.can_add_bank_connection?).to be(true)

    create(:bank_connection, user: user)
    expect(described_class.new(user).can_add_bank_connection?).to be(false)
  end

  it "counts paused and expired connections against the free limit" do
    create(:bank_connection, user: user, status: "paused")

    expect(described_class.new(user).can_add_bank_connection?).to be(false)
  end

  it "allows unlimited connections for subscribed users" do
    stub_pro(user, true)
    create_list(:bank_connection, 3, user: user)

    entitlements = described_class.new(user)
    expect(entitlements.pro?).to be(true)
    expect(entitlements.can_add_bank_connection?).to be(true)
  end

  it "treats an unsubscribed payment processor as free" do
    stub_pro(user, false)

    expect(described_class.new(user).pro?).to be(false)
  end
end
