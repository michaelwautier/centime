module Categorization
  # Multinomial naive Bayes with Laplace smoothing over the user's own
  # corrections. The "model" is two count tables (bayes_tokens,
  # bayes_category_stats) — no training pass, no serialized state.
  class BayesClassifier
    MIN_DOCUMENTS = 10          # don't guess until the user has taught us enough
    MIN_LOG_MARGIN = Math.log(2) # winner must be ≥2x more likely than runner-up

    Guess = Data.define(:category_id, :confident)

    def initialize(user)
      @user = user
    end

    def classify(transaction)
      tokens = Tokenizer.call(transaction)
      return nil if tokens.empty? || total_documents.zero?

      scores = category_ids.index_with { |category_id| score(category_id, tokens) }
      best, runner_up = scores.sort_by { |_, log_prob| -log_prob }.first(2)
      return nil if best.nil?

      confident = trained_enough? && (runner_up.nil? || best.last - runner_up.last >= MIN_LOG_MARGIN)
      Guess.new(category_id: best.first, confident: confident)
    end

    private

    def score(category_id, tokens)
      prior = Math.log(document_counts[category_id].to_f / total_documents)
      token_total = token_totals[category_id].to_i
      vocabulary = [ vocabulary_size, 1 ].max

      tokens.sum(prior) do |token|
        count = token_counts.dig(category_id, token).to_i
        Math.log((count + 1.0) / (token_total + vocabulary))
      end
    end

    def trained_enough? = total_documents >= MIN_DOCUMENTS

    def document_counts
      @document_counts ||= @user.bayes_category_stats.where("document_count > 0").pluck(:category_id, :document_count).to_h
    end

    def category_ids = document_counts.keys
    def total_documents = @total_documents ||= document_counts.values.sum

    def token_counts
      @token_counts ||= @user.bayes_tokens.where("count > 0")
        .pluck(:category_id, :token, :count)
        .each_with_object(Hash.new { |h, k| h[k] = {} }) { |(cat, token, count), acc| acc[cat][token] = count }
    end

    def token_totals
      @token_totals ||= token_counts.transform_values { |tokens| tokens.values.sum }
    end

    def vocabulary_size
      @vocabulary_size ||= token_counts.values.flat_map(&:keys).uniq.size
    end
  end
end
