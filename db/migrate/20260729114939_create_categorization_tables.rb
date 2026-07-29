class CreateCategorizationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :categorization_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :matcher_type, null: false, default: "contains"
      t.string :pattern, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_check_constraint :categorization_rules, "matcher_type IN ('contains', 'equals')",
      name: "categorization_rules_matcher_type_check"

    create_table :merchant_category_mappings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :merchant_key, null: false
      t.integer :hit_count, null: false, default: 1

      t.timestamps
    end
    add_index :merchant_category_mappings, [ :user_id, :merchant_key ], unique: true

    create_table :bayes_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end
    add_index :bayes_tokens, [ :user_id, :category_id, :token ], unique: true

    create_table :bayes_category_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :document_count, null: false, default: 0

      t.timestamps
    end
    add_index :bayes_category_stats, [ :user_id, :category_id ], unique: true
  end
end
