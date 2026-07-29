require "rails_helper"

RSpec.describe Category do
  subject { build(:category) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id, :kind) }
  it { is_expected.to allow_value("#a1b2c3").for(:color) }
  it { is_expected.not_to allow_value("red").for(:color) }

  describe ".system_defaults" do
    it "returns only user-less template categories" do
      template = create(:category, :system_default)
      create(:category)

      expect(described_class.system_defaults).to contain_exactly(template)
    end
  end

  describe ".active" do
    it "excludes archived categories" do
      active = create(:category)
      create(:category, :archived)

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
