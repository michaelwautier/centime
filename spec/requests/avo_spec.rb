require "rails_helper"

RSpec.describe "Avo admin" do
  it "redirects anonymous visitors to sign in" do
    get "/avo"

    expect(response).to redirect_to("/users/sign_in")
  end

  it "is not found for regular users" do
    sign_in create(:user)

    get "/avo"

    expect(response).to have_http_status(:not_found)
  end

  it "is accessible to admins" do
    sign_in create(:user, admin: true)

    get "/avo"

    expect(response).to have_http_status(:ok).or have_http_status(:redirect)
  end
end
