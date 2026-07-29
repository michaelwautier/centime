require "rails_helper"

RSpec.describe Billing::HandleDowngrade do
  let(:user) { create(:user) }

  it "pauses all but the oldest syncable connection" do
    oldest = create(:bank_connection, user: user, created_at: 3.days.ago)
    newer = create(:bank_connection, user: user, created_at: 1.day.ago)
    expired = create(:bank_connection, user: user, status: "expired")

    described_class.call(user: user)

    expect(oldest.reload).to be_status_linked
    expect(newer.reload).to be_status_paused
    expect(expired.reload).to be_status_expired
  end

  it "does nothing for users still subscribed" do
    processor = instance_double(Pay::Customer, subscribed?: true)
    allow_any_instance_of(User).to receive(:payment_processor).and_return(processor)
    create_list(:bank_connection, 2, user: user)

    described_class.call(user: user)

    expect(user.bank_connections.where(status: "paused")).to be_empty
  end
end
