require "rails_helper"

RSpec.describe "Subscriptions" do
  let(:user) { create(:user) }

  before { sign_in user }

  it "shows the free plan with an upgrade CTA" do
    get subscription_path

    expect(response.body).to include("Upgrade to Pro")
  end

  it "starts a Stripe Checkout session" do
    checkout_session = Struct.new(:url).new("https://checkout.stripe.com/c/pay/cs_test_123")
    processor = instance_double(Pay::Stripe::Customer, checkout: checkout_session)
    allow_any_instance_of(User).to receive(:set_payment_processor)
    allow_any_instance_of(User).to receive(:payment_processor).and_return(processor)

    with_env("STRIPE_PRO_PRICE_ID" => "price_123") do
      post checkout_subscription_path
    end

    expect(response).to redirect_to("https://checkout.stripe.com/c/pay/cs_test_123")
  end

  it "refuses a second bank connection for free users" do
    create(:bank_connection, user: user)
    allow(GoCardless::Client).to receive(:new).and_return(
      instance_double(GoCardless::Client, institutions: [ { "id" => "B2", "name" => "Bank 2" } ])
    )

    post bank_connections_path, params: { institution_id: "B2" }

    expect(user.bank_connections.count).to eq(1)
    expect(response).to redirect_to(subscription_path)
  end

  def with_env(vars)
    original = vars.keys.index_with { |key| ENV[key] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end
end
