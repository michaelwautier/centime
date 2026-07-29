require "rails_helper"

RSpec.describe BankAccounts::SyncTransactions do
  let(:account) { create(:bank_account) }
  let(:client) { instance_double(GoCardless::Client) }

  def stub_feed(booked: [], pending: [])
    allow(client).to receive(:account_transactions).and_return(
      "transactions" => { "booked" => booked, "pending" => pending }
    )
    allow(client).to receive(:account_balances).and_return(
      "balances" => [ { "balanceType" => "interimAvailable", "balanceAmount" => { "amount" => "1234.56" } } ]
    )
  end

  def payload(id, amount: "-10.00", date: "2026-07-10", merchant: "SHOP")
    {
      "transactionId" => id,
      "bookingDate" => date,
      "transactionAmount" => { "amount" => amount, "currency" => "EUR" },
      "creditorName" => merchant
    }
  end

  it "inserts new transactions and refreshes the balance" do
    stub_feed(booked: [ payload("t1"), payload("t2", amount: "250.00") ])

    described_class.call(account, client: client)

    expect(account.transactions.count).to eq(2)
    expect(account.reload.balance_cents).to eq(123_456)
    expect(account.bank_connection.reload.last_synced_at).to be_present
  end

  it "is idempotent across runs" do
    stub_feed(booked: [ payload("t1") ])

    2.times { described_class.call(account, client: client) }

    expect(account.transactions.count).to eq(1)
  end

  it "never overwrites user categorization on re-sync" do
    stub_feed(booked: [ payload("t1", merchant: "SNCF") ])
    described_class.call(account, client: client)

    category = create(:category, user: account.bank_connection.user)
    account.transactions.first.update!(category: category, categorization_source: "manual", description: "edited")

    described_class.call(account, client: client)

    transaction = account.transactions.first
    expect(transaction.category).to eq(category)
    expect(transaction.description).to eq("edited")
  end

  it "flips pending transactions to booked when they settle, keeping their category" do
    pending_payload = payload("t9").except("bookingDate").merge("valueDate" => "2026-07-11")
    stub_feed(pending: [ pending_payload ])
    described_class.call(account, client: client)
    expect(account.transactions.first).to be_pending

    category = create(:category, user: account.bank_connection.user)
    account.transactions.first.update!(category: category)

    stub_feed(booked: [ payload("t9", date: "2026-07-12") ])
    described_class.call(account, client: client)

    transaction = account.transactions.sole
    expect(transaction).not_to be_pending
    expect(transaction.category).to eq(category)
    expect(transaction.booked_on).to eq(Date.new(2026, 7, 11)) # original row untouched
  end

  it "marks the connection expired when consent has lapsed" do
    allow(client).to receive(:account_transactions).and_raise(GoCardless::ConsentExpiredError, "EUA expired")

    expect { described_class.call(account, client: client) }.to raise_error(GoCardless::ConsentExpiredError)
    expect(account.bank_connection.reload).to be_status_expired
  end

  it "records sync errors on the connection" do
    allow(client).to receive(:account_transactions).and_raise(GoCardless::Error, "boom")

    expect { described_class.call(account, client: client) }.to raise_error(GoCardless::Error)
    expect(account.bank_connection.reload.last_sync_error).to eq("boom")
  end
end
