require "rails_helper"

RSpec.describe GoCardless::Client do
  subject(:client) { described_class.new(secret_id: "sid", secret_key: "skey") }

  let(:base) { GoCardless::Client::BASE_URL }

  before do
    Rails.cache.delete(GoCardless::Client::TOKEN_CACHE_KEY)
    stub_request(:post, "#{base}/token/new/")
      .to_return(status: 200, body: { access: "token-123" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "fetches institutions with a bearer token" do
    stub = stub_request(:get, "#{base}/institutions/?country=FR")
      .with(headers: { "Authorization" => "Bearer token-123" })
      .to_return(status: 200, body: [ { "id" => "BANK_FR", "name" => "Bank" } ].to_json)

    expect(client.institutions(country: "FR")).to eq([ { "id" => "BANK_FR", "name" => "Bank" } ])
    expect(stub).to have_been_requested
  end

  it "requests the token only once thanks to caching" do
    stub_request(:get, "#{base}/requisitions/abc/").to_return(status: 200, body: {}.to_json)

    with_memory_cache do
      2.times { client.requisition("abc") }
    end

    expect(a_request(:post, "#{base}/token/new/")).to have_been_made.once
  end

  it "raises RateLimitedError on 429" do
    stub_request(:get, "#{base}/accounts/a1/transactions/")
      .to_return(status: 429, body: { detail: "rate limit exceeded" }.to_json)

    expect { client.account_transactions("a1") }.to raise_error(GoCardless::RateLimitedError, /rate limit/)
  end

  it "raises ConsentExpiredError when the EUA has expired" do
    stub_request(:get, "#{base}/accounts/a1/transactions/")
      .to_return(status: 401, body: { detail: "End User Agreement (EUA) has expired" }.to_json)

    expect { client.account_transactions("a1") }.to raise_error(GoCardless::ConsentExpiredError)
  end

  it "raises a generic error with details on other failures" do
    stub_request(:post, "#{base}/requisitions/")
      .to_return(status: 400, body: { detail: "invalid institution" }.to_json)

    expect {
      client.create_requisition(institution_id: "X", redirect: "https://x", reference: "r")
    }.to raise_error(GoCardless::Error, /invalid institution/)
  end

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end
