module Users
  class SessionsController < Devise::SessionsController
    rate_limit to: 10, within: 1.minute, only: :create
    rate_limit to: 5, within: 1.minute, only: :create, name: "sessions/email",
      by: -> { params.dig(:user, :email).to_s.downcase.presence || request.remote_ip }
  end
end
