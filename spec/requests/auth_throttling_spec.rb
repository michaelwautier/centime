require "rails_helper"

RSpec.describe "Authentication throttling" do
  it "throttles repeated sign-in attempts for the same email" do
    6.times do
      post user_session_path, params: { user: { email: "victim@example.com", password: "wrong" } }
    end

    expect(response).to have_http_status(:too_many_requests)
  end

  it "does not throttle a handful of attempts" do
    2.times do
      post user_session_path, params: { user: { email: "someone@example.com", password: "wrong" } }
    end

    expect(response).not_to have_http_status(:too_many_requests)
  end

  it "throttles rapid password reset requests" do
    6.times do
      post user_password_path, params: { user: { email: "someone@example.com" } }
    end

    expect(response).to have_http_status(:too_many_requests)
  end
end
