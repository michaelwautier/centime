require "rails_helper"

RSpec.describe "Manual expense tracking", type: :system do
  before do
    create(:category, :system_default, name: "Groceries", kind: "expense")
    create(:category, :system_default, name: "Salary", kind: "income")
  end

  it "signs up, adds an expense, and sees it on the dashboard" do
    visit new_user_registration_path
    fill_in "Email", with: "michael@example.com"
    fill_in "Password", with: "password123", match: :prefer_exact
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("Dashboard").or have_content("signed up")

    visit new_transaction_path
    choose "Expense"
    fill_in "Amount", with: "42.50"
    fill_in "Merchant", with: "Carrefour"
    select "Groceries", from: "Category"
    click_button "Create Transaction"

    expect(page).to have_content("Transaction added.")
    expect(page).to have_content("Carrefour")

    visit root_path
    expect(page).to have_content("€42.50")
  end

  it "recategorizes a transaction inline from the index" do
    user = create(:user)
    Categories::ProvisionDefaults.call(user: user)
    transaction = create(:transaction, user: user, merchant_name: "SNCF", booked_on: Date.current,
                         category: user.categories.find_by(name: "Salary"), categorization_source: "bayes")
    sign_in user

    visit transactions_path
    row = "##{ActionView::RecordIdentifier.dom_id(transaction)}"
    expect(page).to have_css("#{row} .bg-blue-50", text: /auto/i)

    within(row) { select "Groceries", from: "transaction_category_id" }

    # The turbo-stream row replacement drops the "auto" badge once the source is manual.
    expect(page).to have_css(row)
    expect(page).to have_no_css("#{row} .bg-blue-50")
    expect(transaction.reload.category.name).to eq("Groceries")
    expect(transaction).to be_categorized_by_manual
  end
end
