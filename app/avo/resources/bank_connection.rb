class Avo::Resources::BankConnection < Avo::BaseResource
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
    field :user_id, as: :number
    field :institution_id, as: :text
    field :institution_name, as: :text
    field :institution_logo_url, as: :text
    field :requisition_id, as: :text
    field :reference, as: :text
    field :status, as: :select, enum: ::BankConnection.statuses
    field :consent_expires_at, as: :date_time
    field :last_synced_at, as: :date_time
    field :last_sync_error, as: :textarea
    field :last_manual_sync_on, as: :date
    field :user, as: :belongs_to
    field :bank_accounts, as: :has_many
  end
end
