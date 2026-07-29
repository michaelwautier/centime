# What a user's plan allows. Free: one bank connection. Pro: unlimited.
class Entitlements
  FREE_BANK_CONNECTIONS = 1

  class LimitReached < StandardError; end

  def initialize(user)
    @user = user
  end

  def pro?
    @pro ||= @user.payment_processor.present? && @user.payment_processor.subscribed?
  end

  def max_bank_connections
    pro? ? Float::INFINITY : FREE_BANK_CONNECTIONS
  end

  def can_add_bank_connection?
    @user.bank_connections.count < max_bank_connections
  end
end
