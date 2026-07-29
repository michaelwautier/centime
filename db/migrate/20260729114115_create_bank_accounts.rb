class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.references :bank_connection, null: false, foreign_key: true
      t.string :gocardless_account_id, null: false
      t.string :name
      t.string :iban_last4
      t.string :currency, null: false, default: "EUR", limit: 3
      t.bigint :balance_cents
      t.datetime :balance_refreshed_at
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :bank_accounts, :gocardless_account_id, unique: true
  end
end
