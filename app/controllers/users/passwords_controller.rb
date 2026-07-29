module Users
  class PasswordsController < Devise::PasswordsController
    rate_limit to: 5, within: 1.hour, only: :create
  end
end
