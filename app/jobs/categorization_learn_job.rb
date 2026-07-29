# Keeps categorization writes off the request path.
class CategorizationLearnJob < ApplicationJob
  queue_as :default

  def perform(transaction, category, previous_category = nil)
    Categorization::LearnFromCorrection.call(
      transaction: transaction,
      category: category,
      previous_category: previous_category
    )
  end
end
