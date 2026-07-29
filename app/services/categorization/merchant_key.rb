module Categorization
  # Normalizes a merchant label into a stable lookup key:
  # "CARREFOUR CITY 3407 PARIS 09/07" -> "carrefour city paris"
  module MerchantKey
    module_function

    def for(transaction)
      from_text(transaction.merchant_name.presence || transaction.description)
    end

    def from_text(text)
      return nil if text.blank?

      text.downcase
        .gsub(%r{\d{1,4}[-/.]\d{1,2}([-/.]\d{1,4})?}, " ") # dates
        .gsub(/\b(cb|card|paiement|achat|vir|prlv|sepa)\b/, " ")
        .gsub(/[[:digit:]]+/, " ")                          # store numbers, refs
        .gsub(/[^[:alnum:]]+/, " ")
        .squeeze(" ")
        .strip
        .presence
    end
  end
end
