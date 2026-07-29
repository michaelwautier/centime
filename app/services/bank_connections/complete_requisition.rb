module BankConnections
  # Called when the user returns from the bank: fetches the requisition,
  # materializes bank accounts, and kicks off the first sync.
  class CompleteRequisition
    LINKED_STATUS = "LN".freeze

    def self.call(connection:, client: GoCardless::Client.new) = new(connection:, client:).call

    def initialize(connection:, client:)
      @connection = connection
      @client = client
    end

    def call
      requisition = @client.requisition(@connection.requisition_id)

      unless requisition["status"] == LINKED_STATUS
        @connection.update!(status: "error", last_sync_error: "Requisition status: #{requisition["status"]}")
        return false
      end

      accounts = Array(requisition["accounts"]).map { |account_id| upsert_account(account_id) }
      @connection.update!(status: "linked", consent_expires_at: consent_expiry, last_sync_error: nil)

      accounts.each { |account| BankAccountSyncJob.perform_later(account) }
      true
    end

    private

    def upsert_account(account_id)
      details = @client.account_details(account_id).fetch("account", {})

      account = BankAccount.find_or_initialize_by(gocardless_account_id: account_id)
      account.update!(
        bank_connection: @connection,
        name: details["name"].presence || details["product"].presence || @connection.institution_name,
        iban_last4: details["iban"]&.last(4),
        currency: details["currency"].presence || "EUR",
        status: "active"
      )
      account
    end

    # Matches the access_valid_for_days requested on the end-user agreement.
    def consent_expiry
      90.days.from_now
    end
  end
end
