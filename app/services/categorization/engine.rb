module Categorization
  # Suggestion pipeline, first hit wins:
  #   user rule -> learned merchant match -> naive Bayes -> nothing.
  # Instantiate once per batch (sync run) — lookups are memoized.
  class Engine
    Result = Data.define(:category_id, :source)

    def self.call(transaction) = new(transaction.user).call(transaction)

    def initialize(user)
      @user = user
    end

    def call(transaction)
      rule_match(transaction) || merchant_match(transaction) || bayes_match(transaction) ||
        Result.new(category_id: nil, source: "none")
    end

    # Below-threshold Bayes guess for "Suggested" chips in the review UI.
    def suggestion(transaction)
      guess = classifier.classify(transaction)
      guess && active_category_ids.include?(guess.category_id) ? guess.category_id : nil
    end

    private

    def rule_match(transaction)
      rule = rules.find { |r| r.matches?(transaction.merchant_name) || r.matches?(transaction.description) }
      rule && Result.new(category_id: rule.category_id, source: "rule")
    end

    def merchant_match(transaction)
      key = MerchantKey.for(transaction)
      category_id = key && merchant_mappings[key]
      category_id && Result.new(category_id: category_id, source: "merchant")
    end

    def bayes_match(transaction)
      guess = classifier.classify(transaction)
      return nil unless guess&.confident && active_category_ids.include?(guess.category_id)

      Result.new(category_id: guess.category_id, source: "bayes")
    end

    def rules
      @rules ||= @user.categorization_rules.ordered.to_a
    end

    def merchant_mappings
      @merchant_mappings ||= @user.merchant_category_mappings
        .where(category_id: active_category_ids)
        .pluck(:merchant_key, :category_id).to_h
    end

    def classifier
      @classifier ||= BayesClassifier.new(@user)
    end

    def active_category_ids
      @active_category_ids ||= @user.categories.active.ids.to_set
    end
  end
end
