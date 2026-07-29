class Avo::Resources::User < Avo::BaseResource
  self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :email, as: :text
    field :name, as: :text
    field :currency, as: :text
    field :time_zone, as: :text
    field :admin, as: :boolean
    field :pay_customers, as: :has_many
    field :pay_charges, as: :has_many, through: :pay_customers
    field :pay_subscriptions, as: :has_many, through: :pay_customers
    field :payment_processor, as: :has_one
    field :categories, as: :has_many
    field :transactions, as: :has_many
    field :bank_connections, as: :has_many
    field :bank_accounts, as: :has_many, through: :bank_connections
    field :categorization_rules, as: :has_many
    field :merchant_category_mappings, as: :has_many
    field :bayes_tokens, as: :has_many
    field :bayes_category_stats, as: :has_many
  end
end
