class CreateBankConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :institution_id, null: false
      t.string :institution_name, null: false
      t.string :institution_logo_url
      t.string :requisition_id
      t.string :reference, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :consent_expires_at
      t.datetime :last_synced_at
      t.text :last_sync_error
      t.date :last_manual_sync_on

      t.timestamps
    end

    add_index :bank_connections, :requisition_id, unique: true
    add_index :bank_connections, :reference, unique: true
    add_check_constraint :bank_connections,
      "status IN ('pending', 'linked', 'expiring', 'expired', 'revoked', 'paused', 'error')",
      name: "bank_connections_status_check"
  end
end
