class CleanupOldRejectedCollaborationRequests < ActiveRecord::Migration[8.0]
  def change
    # Delete old rejected collaboration requests to allow users to request again
    execute <<-SQL
      DELETE FROM collaboration_requests WHERE status = 'rejected'
    SQL
  end
end
