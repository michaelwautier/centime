require "rails_helper"

RSpec.describe "Health check" do
  it "responds successfully on /up" do
    get rails_health_check_path

    expect(response).to have_http_status(:ok)
  end
end
