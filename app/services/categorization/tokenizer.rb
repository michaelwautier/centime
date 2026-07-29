module Categorization
  # Tokens for the naive Bayes classifier, from merchant + description.
  module Tokenizer
    MIN_LENGTH = 3

    module_function

    def call(transaction)
      text = [ transaction.merchant_name, transaction.description ].compact.join(" ")
      from_text(text)
    end

    def from_text(text)
      text.to_s.downcase
        .split(/[^[:alnum:]]+/)
        .reject { |token| token.length < MIN_LENGTH || token.match?(/\A\d+\z/) }
        .uniq
    end
  end
end
