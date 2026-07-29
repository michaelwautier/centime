require "capybara/cuprite"

# Any Chromium works (CI installs Chrome; Brave is a valid local fallback).
CHROMIUM_PATH = ENV["BROWSER_PATH"].presence ||
  [ "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ].find { |path| File.exist?(path) }

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite, screen_size: [ 1400, 1000 ], options: {
      browser_path: CHROMIUM_PATH,
      browser_options: { "no-sandbox" => nil },
      js_errors: true,
      process_timeout: 15,
      timeout: 10,
      inspector: ENV["INSPECTOR"].present?,
      headless: ENV["HEADLESS"] != "false"
    }.compact
  end
end
