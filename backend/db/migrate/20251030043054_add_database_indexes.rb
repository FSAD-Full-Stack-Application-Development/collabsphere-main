class AddDatabaseIndexes < ActiveRecord::Migration[8.0]
  def change
    # Projects indexes for filtering and sorting
    add_index :projects, :status unless index_exists?(:projects, :status)
    add_index :projects, :visibility unless index_exists?(:projects, :visibility)
    add_index :projects, :created_at unless index_exists?(:projects, :created_at)
    
    # Votes composite index for uniqueness and queries
    add_index :votes, [:user_id, :project_id], unique: true unless index_exists?(:votes, [:user_id, :project_id])
    
    # Messages indexes for chat queries
    add_index :messages, [:sender_id, :receiver_id] unless index_exists?(:messages, [:sender_id, :receiver_id])
    add_index :messages, :is_read unless index_exists?(:messages, :is_read)
    
    # Funds composite index
    add_index :funds, [:project_id, :funder_id] unless index_exists?(:funds, [:project_id, :funder_id])
    
    # Project stats for analytics
    add_index :project_stats, :total_votes unless index_exists?(:project_stats, :total_votes)
    add_index :project_stats, :total_views unless index_exists?(:project_stats, :total_views)
  end
end
