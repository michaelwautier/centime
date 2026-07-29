class Avo::Resources::Category < Avo::BaseResource
  self.icon = "tabler/outline/folder"
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
    field :name, as: :text
    field :kind, as: :select, enum: ::Category.kinds
    field :color, as: :text
    field :archived_at, as: :date_time
    field :user, as: :belongs_to
    field :transactions, as: :has_many
  end
end
