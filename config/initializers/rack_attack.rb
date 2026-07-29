# Brute-force protection on authentication endpoints. Uses the Rails cache
# (Solid Cache in production), so no extra infrastructure.
class Rack::Attack
  cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  throttle("logins/ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.path == "/users/sign_in" && request.post?
  end

  throttle("logins/email", limit: 5, period: 1.minute) do |request|
    if request.path == "/users/sign_in" && request.post?
      request.params.dig("user", "email").to_s.downcase.presence
    end
  end

  throttle("signups/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.path == "/users" && request.post?
  end

  throttle("password_resets/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.path == "/users/password" && request.post?
  end
end
