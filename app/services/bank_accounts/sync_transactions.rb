module BankAccounts
  # Pulls transactions from GoCardless into local rows.
  #
  # Dedup is insert-only on [bank_account_id, external_id]: existing rows are
  # never overwritten, so user categorization always survives a re-sync. The
  # only follow-up write is flipping `pending` off once a transaction books.
  class SyncTransactions
    OVERLAP = 5.days
    MAX_HISTORY = 90.days

    def self.call(account, client: GoCardless::Client.new) = new(account, client:).call

    def initialize(account, client:)
      @account = account
      @connection = account.bank_connection
      @client = client
    end

    def call
      payload = @client.account_transactions(@account.gocardless_account_id, date_from: window_start)

      booked = Array(payload.dig("transactions", "booked"))
      pending = Array(payload.dig("transactions", "pending"))

      inserted_ids = insert_new(booked, pending)
      settle_booked(booked)
      refresh_balance
      @connection.update!(last_synced_at: Time.current, last_sync_error: nil)

      Transaction.where(id: inserted_ids)
    rescue GoCardless::RateLimitedError => e
      record_failure("Rate limited: #{e.message}")
      raise
    rescue GoCardless::ConsentExpiredError => e
      @connection.update!(status: "expired", last_sync_error: e.message)
      raise
    rescue GoCardless::Error => e
      record_failure(e.message)
      raise
    end

    private

    def window_start
      [ @connection.last_synced_at&.-(OVERLAP)&.to_date, MAX_HISTORY.ago.to_date ].compact.max
    end

    def insert_new(booked, pending)
      rows = booked.filter_map { |t| GoCardless::TransactionMapper.call(t, bank_account: @account) } +
        pending.filter_map { |t| GoCardless::TransactionMapper.call(t, bank_account: @account, pending: true) }
      return [] if rows.empty?

      now = Time.current
      rows.each { |row| row.merge!(created_at: now, updated_at: now) }

      result = Transaction.insert_all(
        rows,
        unique_by: "index_transactions_on_bank_account_and_external_id",
        returning: [ :id ]
      )
      result.rows.flatten
    end

    # A transaction that was pending in an earlier sync books later, keeping
    # its external_id. Only the pending flag is updated — nothing else.
    def settle_booked(booked)
      external_ids = booked.filter_map { |t| t["transactionId"].presence || t["internalTransactionId"].presence }
      return if external_ids.empty?

      @account.transactions.where(external_id: external_ids, pending: true).update_all(pending: false, updated_at: Time.current)
    end

    def refresh_balance
      balances = Array(@client.account_balances(@account.gocardless_account_id)["balances"])
      preferred = balances.find { |b| b["balanceType"] == "interimAvailable" } || balances.first
      amount = preferred&.dig("balanceAmount", "amount")
      return if amount.blank?

      @account.update!(balance_cents: (BigDecimal(amount.to_s) * 100).round, balance_refreshed_at: Time.current)
    rescue GoCardless::Error
      nil # balance refresh is best-effort; transaction sync already succeeded
    end

    def record_failure(message)
      @connection.update!(status: "error", last_sync_error: message)
    end
  end
end
