module Categories
  # Copies the system default categories (user_id: nil) to a freshly signed-up user.
  class ProvisionDefaults
    def self.call(user:) = new(user:).call

    def initialize(user:)
      @user = user
    end

    def call
      Category.system_defaults.active.find_each do |template|
        @user.categories.find_or_create_by!(name: template.name, kind: template.kind) do |category|
          category.color = template.color
        end
      end
    end
  end
end
