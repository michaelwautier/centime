class Avo::Resources::Transaction < Avo::BaseResource
  self.icon = "tabler/outline/credit-card-pay"
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
    field :user_id, as: :number
    field :category_id, as: :number
    field :amount_cents, as: :number
    field :currency, as: :text
    field :booked_on, as: :date
    field :description, as: :textarea
    field :merchant_name, as: :text
    field :source, as: :select, enum: ::Transaction.sources
    field :categorization_source, as: :select, enum: ::Transaction.categorization_sources
    field :pending, as: :boolean
    field :bank_account_id, as: :number
    field :external_id, as: :text
    field :user, as: :belongs_to
    field :category, as: :belongs_to
    field :bank_account, as: :belongs_to
  end
end
