class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.bigint :amount_cents, null: false # signed: negative = expense
      t.string :currency, null: false, limit: 3
      t.date :booked_on, null: false
      t.string :description
      t.string :merchant_name
      t.string :source, null: false, default: "manual"
      t.string :categorization_source, null: false, default: "none"
      t.boolean :pending, null: false, default: false

      t.timestamps
    end

    add_index :transactions, [ :user_id, :booked_on ]
  end
end
