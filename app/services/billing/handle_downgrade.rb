module Billing
  # After a Pro subscription ends: pause surplus bank connections (never delete
  # data). The oldest active connection stays; the user can swap later by
  # disconnecting it and reconnecting another.
  class HandleDowngrade
    def self.call(user:) = new(user:).call

    def initialize(user:)
      @user = user
    end

    def call
      return if Entitlements.new(@user).pro?

      keep = @user.bank_connections.syncable.order(:created_at).limit(Entitlements::FREE_BANK_CONNECTIONS)
      @user.bank_connections.syncable.where.not(id: keep.ids)
        .update_all(status: "paused", updated_at: Time.current)
    end
  end
end
