class AddBankAccountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :bank_account, foreign_key: true
    add_column :transactions, :external_id, :string

    add_index :transactions, [ :bank_account_id, :external_id ],
      unique: true, where: "external_id IS NOT NULL",
      name: "index_transactions_on_bank_account_and_external_id"
  end
end
