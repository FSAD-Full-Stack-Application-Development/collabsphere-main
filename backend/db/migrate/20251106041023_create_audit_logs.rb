class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :resource_type
      t.integer :resource_id
      t.text :details
      t.string :ip_address

      t.timestamps
    end
    
    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :created_at
  end
end
