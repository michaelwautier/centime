require "rails_helper"

RSpec.describe GoCardless::TransactionMapper do
  let(:account) { create(:bank_account) }

  it "maps a typical booked transaction" do
    payload = {
      "transactionId" => "tx-1",
      "bookingDate" => "2026-07-10",
      "transactionAmount" => { "amount" => "-23.45", "currency" => "EUR" },
      "creditorName" => "CARREFOUR CITY",
      "remittanceInformationUnstructured" => "CB CARREFOUR 09/07"
    }

    attrs = described_class.call(payload, bank_account: account)

    expect(attrs).to include(
      external_id: "tx-1",
      amount_cents: -2345,
      currency: "EUR",
      booked_on: Date.new(2026, 7, 10),
      merchant_name: "CARREFOUR CITY",
      description: "CB CARREFOUR 09/07",
      source: "bank_sync",
      pending: false
    )
  end

  it "uses debtorName for incoming transfers and falls back to internalTransactionId and valueDate" do
    payload = {
      "internalTransactionId" => "itx-9",
      "valueDate" => "2026-07-01",
      "transactionAmount" => { "amount" => "1500.00" },
      "debtorName" => "ACME CORP"
    }

    attrs = described_class.call(payload, bank_account: account)

    expect(attrs).to include(external_id: "itx-9", amount_cents: 150_000, merchant_name: "ACME CORP",
                             booked_on: Date.new(2026, 7, 1), currency: account.currency)
  end

  it "returns nil for unusable payloads" do
    expect(described_class.call({}, bank_account: account)).to be_nil
    expect(described_class.call({ "transactionId" => "x" }, bank_account: account)).to be_nil
    expect(described_class.call(
      { "transactionId" => "x", "transactionAmount" => { "amount" => "0.00" }, "bookingDate" => "2026-07-01" },
      bank_account: account
    )).to be_nil
  end
end
