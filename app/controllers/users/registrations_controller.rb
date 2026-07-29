module Users
  class RegistrationsController < Devise::RegistrationsController
    rate_limit to: 5, within: 1.hour, only: :create

    def create
      super do |user|
        Categories::ProvisionDefaults.call(user: user) if user.persisted?
      end
    end
  end
end
