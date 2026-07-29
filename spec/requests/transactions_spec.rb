require "rails_helper"

RSpec.describe "Transactions" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /transactions" do
    it "lists the current month's transactions" do
      create(:transaction, user: user, description: "Baguette", booked_on: Date.current)

      get transactions_path

      expect(response.body).to include("Baguette")
    end

    it "does not show other users' transactions" do
      create(:transaction, description: "Secret purchase", booked_on: Date.current)

      get transactions_path

      expect(response.body).not_to include("Secret purchase")
    end

    it "filters to uncategorized" do
      categorized = create(:transaction, user: user, description: "Sorted", booked_on: Date.current,
                           category: create(:category, user: user))
      create(:transaction, user: user, description: "Unsorted", booked_on: Date.current)

      get transactions_path(filter: "uncategorized")

      expect(response.body).to include("Unsorted")
      expect(response.body).not_to include(categorized.description)
    end
  end

  describe "POST /transactions" do
    it "creates an expense from form params" do
      expect {
        post transactions_path, params: { transaction: { amount: "12.50", direction: "expense", booked_on: Date.current } }
      }.to change(user.transactions, :count).by(1)

      expect(user.transactions.last.amount_cents).to eq(-1250)
      expect(response).to redirect_to(transactions_path)
    end

    it "re-renders on invalid input" do
      post transactions_path, params: { transaction: { amount: "0", direction: "expense" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /transactions/:id (inline category)" do
    it "recategorizes and marks the source manual" do
      transaction = create(:transaction, user: user, categorization_source: "bayes")
      category = create(:category, user: user)

      patch transaction_path(transaction), params: { transaction: { category_id: category.id } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(transaction.reload.category).to eq(category)
      expect(transaction).to be_categorized_by_manual
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "ignores a category from another user" do
      transaction = create(:transaction, user: user)
      foreign_category = create(:category)

      patch transaction_path(transaction), params: { transaction: { category_id: foreign_category.id } }

      expect(transaction.reload.category).to be_nil
    end
  end

  describe "DELETE /transactions/:id" do
    it "deletes the transaction" do
      transaction = create(:transaction, user: user)

      expect { delete transaction_path(transaction) }.to change(user.transactions, :count).by(-1)
    end

    it "cannot delete another user's transaction" do
      transaction = create(:transaction)

      delete transaction_path(transaction)

      expect(response).to have_http_status(:not_found)
      expect(Transaction.exists?(transaction.id)).to be(true)
    end
  end

  it "requires authentication" do
    sign_out user

    get transactions_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
