class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, foreign_key: true # null = system default template
      t.string :name, null: false
      t.string :kind, null: false
      t.string :color, null: false, default: "#6b7280"
      t.datetime :archived_at

      t.timestamps
    end

    add_index :categories, [ :user_id, :name, :kind ], unique: true
    add_check_constraint :categories, "kind IN ('income', 'expense')", name: "categories_kind_check"
  end
end
