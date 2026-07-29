require "rails_helper"

RSpec.describe "Hotwire Native" do
  describe "path configurations" do
    it "serves iOS rules without authentication" do
      get "/hotwire_native/v1/ios/path_configuration"

      expect(response).to have_http_status(:ok)
      rules = response.parsed_body.fetch("rules")
      expect(rules).to include(hash_including("patterns" => [ "/new$", "/edit$" ]))
    end

    it "serves Android rules without authentication" do
      get "/hotwire_native/v1/android/path_configuration"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key("rules")
    end
  end

  describe "native layout" do
    it "hides the web navigation for Hotwire Native user agents" do
      sign_in create(:user)

      get root_path, headers: { "User-Agent" => "Centime iOS Hotwire Native" }

      expect(response.body).not_to include("Sign out")
    end

    it "shows the web navigation in normal browsers" do
      sign_in create(:user)

      get root_path

      expect(response.body).to include("Sign out")
    end
  end
end
