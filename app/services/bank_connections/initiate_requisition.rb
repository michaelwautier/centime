module BankConnections
  # Creates the local connection + GoCardless requisition and returns the
  # bank's consent URL to redirect the user to.
  class InitiateRequisition
    Result = Data.define(:connection, :link)

    def self.call(user:, institution:, redirect_url:, client: GoCardless::Client.new)
      new(user:, institution:, redirect_url:, client:).call
    end

    def initialize(user:, institution:, redirect_url:, client:)
      @user = user
      @institution = institution
      @redirect_url = redirect_url
      @client = client
    end

    def call
      connection = @user.bank_connections.create!(
        institution_id: @institution.fetch("id"),
        institution_name: @institution.fetch("name"),
        institution_logo_url: @institution["logo"],
        reference: SecureRandom.uuid,
        status: "pending"
      )

      agreement = @client.create_end_user_agreement(institution_id: connection.institution_id)
      requisition = @client.create_requisition(
        institution_id: connection.institution_id,
        redirect: @redirect_url,
        reference: connection.reference,
        agreement_id: agreement["id"]
      )

      connection.update!(requisition_id: requisition.fetch("id"))
      Result.new(connection: connection, link: requisition.fetch("link"))
    end
  end
end
