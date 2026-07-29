module GoCardless
  # Maps one GoCardless transaction payload to Transaction attributes.
  # Payload shapes vary by bank — every field access is defensive.
  class TransactionMapper
    def self.call(payload, bank_account:, pending: false) = new(payload, bank_account:, pending:).call

    def initialize(payload, bank_account:, pending:)
      @payload = payload
      @bank_account = bank_account
      @pending = pending
    end

    def call
      return nil if external_id.blank? || amount_cents.nil? || amount_cents.zero? || booked_on.nil?

      {
        user_id: @bank_account.bank_connection.user_id,
        bank_account_id: @bank_account.id,
        external_id: external_id,
        amount_cents: amount_cents,
        currency: currency,
        booked_on: booked_on,
        description: description&.truncate(255),
        merchant_name: merchant_name&.truncate(255),
        source: "bank_sync",
        categorization_source: "none",
        pending: @pending
      }
    end

    private

    def external_id
      @payload["transactionId"].presence || @payload["internalTransactionId"].presence
    end

    def amount_cents
      amount = @payload.dig("transactionAmount", "amount")
      return nil if amount.blank?

      (BigDecimal(amount.to_s) * 100).round
    rescue ArgumentError
      nil
    end

    def currency
      @payload.dig("transactionAmount", "currency").presence || @bank_account.currency
    end

    def booked_on
      raw = @payload["bookingDate"].presence || @payload["valueDate"].presence
      raw && Date.parse(raw)
    rescue ArgumentError
      nil
    end

    def merchant_name
      counterparty = amount_cents&.negative? ? @payload["creditorName"] : @payload["debtorName"]
      counterparty.presence
    end

    def description
      remittance = @payload["remittanceInformationUnstructured"].presence ||
        Array(@payload["remittanceInformationUnstructuredArray"]).join(" ").presence
      remittance || @payload["additionalInformation"].presence
    end
  end
end
