require "rails_helper"

RSpec.describe "Categories" do
  let(:user) { create(:user) }

  before { sign_in user }

  it "creates a category" do
    expect {
      post categories_path, params: { category: { name: "Pets", kind: "expense", color: "#123abc" } }
    }.to change(user.categories, :count).by(1)
  end

  it "rejects duplicate names within the same kind" do
    create(:category, user: user, name: "Pets", kind: "expense")

    post categories_path, params: { category: { name: "Pets", kind: "expense", color: "#123abc" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "archives instead of destroying" do
    category = create(:category, user: user)
    create(:transaction, user: user, category: category)

    delete category_path(category)

    expect(category.reload).to be_archived
    expect(user.transactions.where(category: category).count).to eq(1)
  end
end
