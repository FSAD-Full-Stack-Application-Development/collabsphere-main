class AddModerationFlags < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_suspended, :boolean, default: false, null: false
    add_column :users, :is_reported, :boolean, default: false, null: false
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspended_reason, :text
    add_column :users, :suspended_by_id, :uuid
    
    add_column :projects, :is_hidden, :boolean, default: false, null: false
    add_column :projects, :is_reported, :boolean, default: false, null: false
    add_column :projects, :hidden_at, :datetime
    add_column :projects, :hidden_reason, :text
    add_column :projects, :hidden_by_id, :uuid
    
    add_column :comments, :is_hidden, :boolean, default: false, null: false
    add_column :comments, :is_reported, :boolean, default: false, null: false
    add_column :comments, :hidden_at, :datetime
    add_column :comments, :hidden_reason, :text
    add_column :comments, :hidden_by_id, :uuid
    
    add_index :users, :is_suspended
    add_index :users, :is_reported
    add_index :projects, :is_hidden
    add_index :projects, :is_reported
    add_index :comments, :is_hidden
    add_index :comments, :is_reported
    
    add_foreign_key :users, :users, column: :suspended_by_id
    add_foreign_key :projects, :users, column: :hidden_by_id
    add_foreign_key :comments, :users, column: :hidden_by_id
  end
end
