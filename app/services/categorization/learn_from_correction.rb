module Categorization
  # Train-on-write: every user categorization (or correction) updates the
  # merchant mapping and the Bayes count tables. A correction also unlearns
  # the previous category so bad guesses don't linger.
  class LearnFromCorrection
    def self.call(transaction:, category:, previous_category: nil)
      new(transaction:, category:, previous_category:).call
    end

    def initialize(transaction:, category:, previous_category:)
      @transaction = transaction
      @user = transaction.user
      @category = category
      @previous_category = previous_category
    end

    def call
      return if @category.nil?

      ApplicationRecord.transaction do
        unlearn_previous if @previous_category && @previous_category != @category
        learn_merchant
        learn_tokens
      end
    end

    private

    def learn_merchant
      key = MerchantKey.for(@transaction)
      return if key.blank?

      mapping = @user.merchant_category_mappings.find_or_initialize_by(merchant_key: key)
      if mapping.persisted? && mapping.category_id == @category.id
        mapping.increment!(:hit_count)
      else
        # New key, or the user disagrees with the stored mapping: repoint it.
        mapping.update!(category: @category, hit_count: 1)
      end
    end

    def learn_tokens
      stat = @user.bayes_category_stats.find_or_create_by!(category: @category)
      stat.increment!(:document_count)

      Tokenizer.call(@transaction).each do |token|
        row = @user.bayes_tokens.find_or_create_by!(category: @category, token: token)
        row.increment!(:count)
      end
    end

    def unlearn_previous
      stat = @user.bayes_category_stats.find_by(category: @previous_category)
      stat&.update!(document_count: [ stat.document_count - 1, 0 ].max)

      Tokenizer.call(@transaction).each do |token|
        row = @user.bayes_tokens.find_by(category: @previous_category, token: token)
        row&.update!(count: [ row.count - 1, 0 ].max)
      end
    end
  end
end
