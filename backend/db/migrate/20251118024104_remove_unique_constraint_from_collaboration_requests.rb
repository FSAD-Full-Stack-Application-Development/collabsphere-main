class RemoveUniqueConstraintFromCollaborationRequests < ActiveRecord::Migration[8.0]
  def change
    # Remove the unique index that prevents multiple requests per user-project pair
    remove_index :collaboration_requests, [:project_id, :user_id], name: "index_collab_requests_on_project_and_user"
    
    # Add a non-unique index for performance
    add_index :collaboration_requests, [:project_id, :user_id], name: "index_collab_requests_on_project_and_user"
  end
end
