require "rails_helper"

RSpec.describe "Theme switching", type: :system do
  before { sign_in create(:user) }

  it "defaults to auto and lets the user force and persist a theme" do
    visit root_path

    # Auto follows whatever the browser reports as the system preference.
    expect(page).to have_select("theme", selected: "Auto")
    system_dark = page.evaluate_script('matchMedia("(prefers-color-scheme: dark)").matches')
    expect(page.has_css?("html.dark")).to eq(system_dark)

    select "Dark", from: "theme"
    expect(page).to have_css("html.dark")

    # The choice sticks across a full page load.
    visit transactions_path
    expect(page).to have_css("html.dark")
    expect(page).to have_select("theme", selected: "Dark")

    select "Light", from: "theme"
    expect(page).to have_no_css("html.dark")

    visit root_path
    expect(page).to have_no_css("html.dark")
    expect(page).to have_select("theme", selected: "Light")
  end
end
