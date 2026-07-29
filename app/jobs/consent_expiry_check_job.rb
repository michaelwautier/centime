# Flags connections whose 90-day PSD2 consent is about to lapse and notifies
# the user so they can renew before sync stops. Runs daily via recurring.yml.
class ConsentExpiryCheckJob < ApplicationJob
  queue_as :default

  def perform
    BankConnection.status_linked
      .where(consent_expires_at: ...BankConnection::CONSENT_WARNING_WINDOW.from_now)
      .find_each do |connection|
        connection.update!(status: "expiring")
        ConsentMailer.with(bank_connection: connection).expiring_soon.deliver_later
      end

    BankConnection.where(status: [ :linked, :expiring ])
      .where(consent_expires_at: ...Time.current)
      .update_all(status: "expired", updated_at: Time.current)
  end
end
