require "rails_helper"

RSpec.describe "Bank connections" do
  let(:user) { create(:user) }
  let(:client) { instance_double(GoCardless::Client) }

  before do
    sign_in user
    allow(GoCardless::Client).to receive(:new).and_return(client)
  end

  describe "POST /bank_connections" do
    before do
      allow(client).to receive(:institutions).and_return(
        [ { "id" => "SANDBOXFINANCE_SFIN0000", "name" => "Sandbox Finance", "logo" => nil } ]
      )
      allow(client).to receive(:create_end_user_agreement).and_return({ "id" => "eua-1" })
      allow(client).to receive(:create_requisition).and_return(
        { "id" => "req-1", "link" => "https://ob.gocardless.com/psd2/start/xyz" }
      )
    end

    it "creates a pending connection and redirects to the bank" do
      post bank_connections_path, params: { institution_id: "SANDBOXFINANCE_SFIN0000" }

      connection = user.bank_connections.sole
      expect(connection).to be_status_pending
      expect(connection.requisition_id).to eq("req-1")
      expect(response).to redirect_to("https://ob.gocardless.com/psd2/start/xyz")
    end

    it "rejects an unknown institution" do
      post bank_connections_path, params: { institution_id: "NOPE" }

      expect(user.bank_connections.count).to eq(0)
      expect(response).to redirect_to(new_bank_connection_path)
    end
  end

  describe "GET /bank_connections/callback" do
    it "completes the requisition and creates accounts" do
      connection = create(:bank_connection, user: user, status: "pending", reference: "cb-ref", requisition_id: "req-9")
      allow(client).to receive(:requisition).with("req-9").and_return(
        { "status" => "LN", "accounts" => [ "acct-1" ] }
      )
      allow(client).to receive(:account_details).with("acct-1").and_return(
        { "account" => { "iban" => "FR7612345678901234", "currency" => "EUR", "name" => "Compte courant" } }
      )

      expect {
        get bank_connections_callback_path(ref: "cb-ref")
      }.to have_enqueued_job(BankAccountSyncJob)

      expect(connection.reload).to be_status_linked
      expect(connection.bank_accounts.sole.iban_last4).to eq("1234")
      expect(response).to redirect_to(bank_connections_path)
    end

    it "flags the connection when the bank flow was not completed" do
      connection = create(:bank_connection, user: user, status: "pending", reference: "cb-ref2", requisition_id: "req-10")
      allow(client).to receive(:requisition).with("req-10").and_return({ "status" => "CR", "accounts" => [] })

      get bank_connections_callback_path(ref: "cb-ref2")

      expect(connection.reload).to be_status_error
    end
  end

  describe "POST /bank_connections/:id/sync" do
    it "enqueues syncs once per day" do
      connection = create(:bank_connection, user: user)
      create(:bank_account, bank_connection: connection)

      expect { post sync_bank_connection_path(connection) }.to have_enqueued_job(BankAccountSyncJob)
      expect(connection.reload.last_manual_sync_on).to eq(Date.current)

      expect { post sync_bank_connection_path(connection) }.not_to have_enqueued_job(BankAccountSyncJob)
    end
  end

  describe "DELETE /bank_connections/:id" do
    it "removes the connection but keeps imported transactions" do
      connection = create(:bank_connection, user: user)
      bank_account = create(:bank_account, bank_connection: connection)
      transaction = create(:transaction, user: user, bank_account: bank_account, external_id: "t1", source: "bank_sync")
      allow(client).to receive(:delete_requisition)

      delete bank_connection_path(connection)

      expect(BankConnection.exists?(connection.id)).to be(false)
      expect(transaction.reload.bank_account_id).to be_nil
    end
  end
end
