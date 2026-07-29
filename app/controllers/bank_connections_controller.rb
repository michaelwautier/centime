class BankConnectionsController < ApplicationController
  DEFAULT_COUNTRY = "FR".freeze

  def index
    @bank_connections = current_user.bank_connections.includes(:bank_accounts).order(:created_at)
  end

  def new
    @country = params[:country].presence || DEFAULT_COUNTRY
    @institutions = cached_institutions(@country)
    @query = params[:q].to_s.strip
    @institutions = @institutions.select { |i| i["name"].downcase.include?(@query.downcase) } if @query.present?
  rescue GoCardless::Error => e
    redirect_to bank_connections_path, alert: "Could not load banks: #{e.message}"
  end

  def create
    institution = cached_institutions(params[:country].presence || DEFAULT_COUNTRY)
      .find { |i| i["id"] == params[:institution_id] }
    return redirect_to new_bank_connection_path, alert: "Unknown bank." if institution.nil?

    result = BankConnections::InitiateRequisition.call(
      user: current_user,
      institution: institution,
      redirect_url: bank_connections_callback_url
    )
    redirect_to result.link, allow_other_host: true
  rescue Entitlements::LimitReached
    redirect_to subscription_path, alert: "The free plan includes one bank connection. Upgrade to Pro to connect more."
  rescue GoCardless::Error => e
    redirect_to bank_connections_path, alert: "Could not connect to the bank: #{e.message}"
  end

  def destroy
    connection = current_user.bank_connections.find(params[:id])
    begin
      GoCardless::Client.new.delete_requisition(connection.requisition_id) if connection.requisition_id
    rescue GoCardless::Error
      # remote cleanup is best-effort; local removal must always work
    end
    connection.destroy!
    redirect_to bank_connections_path, notice: "Bank disconnected.", status: :see_other
  end

  # Manual "Sync now" — once per day per connection on top of the nightly sync,
  # to stay within GoCardless's 4 calls/day/account rate limit.
  def sync
    connection = current_user.bank_connections.find(params[:id])
    if connection.manual_sync_available?
      connection.update!(last_manual_sync_on: Date.current)
      connection.bank_accounts.find_each { |account| BankAccountSyncJob.perform_later(account) }
      redirect_to bank_connections_path, notice: "Sync started."
    else
      redirect_to bank_connections_path, alert: "Manual sync is available once per day."
    end
  end

  private

  def cached_institutions(country)
    Rails.cache.fetch("gocardless/institutions/#{country}", expires_in: 24.hours) do
      GoCardless::Client.new.institutions(country: country)
    end
  end
end
