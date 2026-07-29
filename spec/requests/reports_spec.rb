require "rails_helper"

RSpec.describe "Reports" do
  let(:user) { create(:user) }

  before { sign_in user }

  it "renders the monthly report" do
    category = create(:category, user: user, name: "Groceries")
    create(:transaction, user: user, category: category, amount_cents: -1_500, booked_on: Date.current)

    get reports_path

    expect(response.body).to include("Groceries")
    expect(response.body).to include("Income vs expenses")
  end

  it "exports the month's transactions as CSV" do
    create(:transaction, user: user, merchant_name: "Carrefour", amount_cents: -1_234, booked_on: Date.current)

    get transactions_path(format: :csv)

    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("Date,Description,Merchant,Category,Amount,Currency,Source")
    expect(response.body).to include("Carrefour")
    expect(response.body).to include("-12.34")
  end
end
