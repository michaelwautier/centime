# Fans out one sync job per syncable bank account. Scheduled daily via
# config/recurring.yml — GoCardless free tier allows 4 calls/day/account.
class DailyBankSyncJob < ApplicationJob
  queue_as :default

  def perform
    BankAccount.joins(:bank_connection)
      .merge(BankConnection.syncable)
      .find_each { |account| BankAccountSyncJob.perform_later(account) }
  end
end
