module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      super do |user|
        Categories::ProvisionDefaults.call(user: user) if user.persisted?
      end
    end
  end
end
