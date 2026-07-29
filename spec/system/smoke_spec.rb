require "rails_helper"

RSpec.describe "Browser smoke test", type: :system do
  it "renders the health check page in a real browser" do
    visit rails_health_check_path

    expect(page.status_code).to eq(200)
  end
end
