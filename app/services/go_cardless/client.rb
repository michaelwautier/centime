require "net/http"

module GoCardless
  class Error < StandardError; end
  class RateLimitedError < Error; end
  class ConsentExpiredError < Error; end
  class NotFoundError < Error; end

  # Minimal client for the GoCardless Bank Account Data API (v2).
  # https://developer.gocardless.com/bank-account-data/overview
  class Client
    BASE_URL = "https://bankaccountdata.gocardless.com/api/v2".freeze
    TOKEN_CACHE_KEY = "gocardless/access_token".freeze

    def initialize(secret_id: ENV.fetch("GOCARDLESS_SECRET_ID"), secret_key: ENV.fetch("GOCARDLESS_SECRET_KEY"))
      @secret_id = secret_id
      @secret_key = secret_key
    end

    def institutions(country:)
      get("/institutions/", country: country)
    end

    def create_end_user_agreement(institution_id:, max_historical_days: 90, access_valid_for_days: 90)
      post("/agreements/enduser/",
        institution_id: institution_id,
        max_historical_days: max_historical_days,
        access_valid_for_days: access_valid_for_days,
        access_scope: [ "balances", "details", "transactions" ])
    end

    def create_requisition(institution_id:, redirect:, reference:, agreement_id: nil, user_language: "EN")
      post("/requisitions/", {
        institution_id: institution_id,
        redirect: redirect,
        reference: reference,
        agreement: agreement_id,
        user_language: user_language
      }.compact)
    end

    def requisition(id)
      get("/requisitions/#{id}/")
    end

    def delete_requisition(id)
      request(Net::HTTP::Delete, "/requisitions/#{id}/")
    end

    def account_details(id)
      get("/accounts/#{id}/details/")
    end

    def account_balances(id)
      get("/accounts/#{id}/balances/")
    end

    def account_transactions(id, date_from: nil)
      get("/accounts/#{id}/transactions/", { date_from: date_from&.to_s }.compact)
    end

    private

    def get(path, params = {})
      request(Net::HTTP::Get, path, params: params)
    end

    def post(path, body)
      request(Net::HTTP::Post, path, body: body)
    end

    def request(verb, path, params: {}, body: nil, auth: true)
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      http_request = verb.new(uri)
      http_request["Accept"] = "application/json"
      http_request["Authorization"] = "Bearer #{access_token}" if auth
      if body
        http_request["Content-Type"] = "application/json"
        http_request.body = body.to_json
      end

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(http_request) }
      handle(response)
    end

    def handle(response)
      payload = response.body.presence && JSON.parse(response.body)

      case response.code.to_i
      when 200..299 then payload
      when 401, 403
        raise ConsentExpiredError, error_message(payload) if consent_expired?(payload)
        raise Error, error_message(payload)
      when 404 then raise NotFoundError, error_message(payload)
      when 429 then raise RateLimitedError, error_message(payload)
      else raise Error, "GoCardless API error #{response.code}: #{error_message(payload)}"
      end
    end

    def consent_expired?(payload)
      payload.to_s.match?(/EUA.*expired|access has expired|ConsentExpired/i)
    end

    def error_message(payload)
      return "unknown error" unless payload.is_a?(Hash)

      payload["detail"] || payload["summary"] || payload.to_s
    end

    # Access tokens last 24h; cache with margin. New token on every miss —
    # refresh-token flow is not worth the extra state for a daily sync.
    def access_token
      Rails.cache.fetch(TOKEN_CACHE_KEY, expires_in: 23.hours) do
        payload = { secret_id: @secret_id, secret_key: @secret_key }
        uri = URI("#{BASE_URL}/token/new/")
        http_request = Net::HTTP::Post.new(uri)
        http_request["Accept"] = "application/json"
        http_request["Content-Type"] = "application/json"
        http_request.body = payload.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(http_request) }
        handle(response).fetch("access")
      end
    end
  end
end
