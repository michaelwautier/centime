class Avo::Resources::BankAccount < Avo::BaseResource
  # self.icon = "tabler/outline/users"
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
    field :bank_connection_id, as: :number
    field :gocardless_account_id, as: :text
    field :name, as: :text
    field :iban_last4, as: :text
    field :currency, as: :text
    field :balance_cents, as: :number
    field :balance_refreshed_at, as: :date_time
    field :status, as: :text
    field :bank_connection, as: :belongs_to
    field :user, as: :belongs_to
    field :transactions, as: :has_many
  end
end
