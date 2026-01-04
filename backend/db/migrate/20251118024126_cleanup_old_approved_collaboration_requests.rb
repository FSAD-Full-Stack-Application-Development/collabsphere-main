class CleanupOldApprovedCollaborationRequests < ActiveRecord::Migration[8.0]
  def change
    # Delete old approved collaboration requests since they're no longer needed
    # once someone becomes a collaborator
    execute <<-SQL
      DELETE FROM collaboration_requests WHERE status = 'approved'
    SQL
  end
end
