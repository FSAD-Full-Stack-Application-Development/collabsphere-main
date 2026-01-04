class CreateFundingRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :funding_requests, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true
      t.references :funder, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :note
      t.string :status, default: 'pending', null: false
      t.uuid :verified_by
      t.datetime :verified_at
      
      t.timestamps
    end
    
    add_index :funding_requests, [:project_id, :funder_id, :status]
    add_index :funding_requests, :status
    add_foreign_key :funding_requests, :users, column: :verified_by
  end
end
