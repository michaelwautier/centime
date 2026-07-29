class BankAccountSyncJob < ApplicationJob
  queue_as :default

  # Rate limits (4 calls/day/account) mean a same-day retry would fail again.
  discard_on GoCardless::RateLimitedError, GoCardless::ConsentExpiredError

  retry_on GoCardless::Error, wait: 5.minutes, attempts: 2

  def perform(bank_account)
    return unless bank_account.bank_connection.syncable?

    BankAccounts::SyncTransactions.call(bank_account)
  end
end
