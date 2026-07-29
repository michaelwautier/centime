require "rails_helper"

RSpec.describe "Categorization during bank sync" do
  let(:account) { create(:bank_account) }
  let(:user) { account.bank_connection.user }
  let(:groceries) { create(:category, user: user, name: "Groceries") }
  let(:client) { instance_double(GoCardless::Client) }

  def payload(id, merchant)
    {
      "transactionId" => id,
      "bookingDate" => "2026-07-10",
      "transactionAmount" => { "amount" => "-10.00", "currency" => "EUR" },
      "creditorName" => merchant
    }
  end

  it "auto-categorizes newly synced transactions from learned corrections" do
    Categorization::LearnFromCorrection.call(
      transaction: build(:transaction, user: user, merchant_name: "CARREFOUR CITY 01"),
      category: groceries
    )

    allow(client).to receive(:account_transactions).and_return(
      "transactions" => { "booked" => [ payload("t1", "CARREFOUR CITY 99"), payload("t2", "UNKNOWN SHOP") ] }
    )
    allow(client).to receive(:account_balances).and_return("balances" => [])

    BankAccounts::SyncTransactions.call(account, client: client)

    categorized = account.transactions.find_by(external_id: "t1")
    uncategorized = account.transactions.find_by(external_id: "t2")

    expect(categorized.category).to eq(groceries)
    expect(categorized).to be_categorized_by_merchant
    expect(uncategorized.category).to be_nil
    expect(uncategorized).to be_categorized_by_none
  end
end
