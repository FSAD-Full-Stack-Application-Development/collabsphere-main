class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :notifiable_type, null: false
      t.uuid :notifiable_id, null: false
      t.uuid :actor_id
      t.text :message, null: false
      t.json :metadata
      t.boolean :read, default: false, null: false
      t.datetime :read_at
      
      t.timestamps
    end
    
    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :notification_type
    add_index :notifications, :created_at
    add_foreign_key :notifications, :users, column: :actor_id
  end
end
