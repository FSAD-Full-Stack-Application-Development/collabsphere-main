class CreateCollaborationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :collaboration_requests do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.text :message

      t.timestamps
    end
    
    add_index :collaboration_requests, [:project_id, :user_id], unique: true, name: 'index_collab_requests_on_project_and_user'
    add_index :collaboration_requests, :status
  end
end
