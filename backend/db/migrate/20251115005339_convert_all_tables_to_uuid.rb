class ConvertAllTablesToUuid < ActiveRecord::Migration[8.0]
  def up
    # List of all tables in order (dependencies last)
    tables = %w[
      users tags projects
      collaborations collaboration_requests comments funds messages
      project_stats project_tags resources votes user_tags
      audit_logs reports api_logs
    ]

    # Step 1: Add UUID columns to all tables
    tables.each do |table|
      add_column table, :uuid, :uuid, default: "gen_random_uuid()", null: false
      add_index table, :uuid, unique: true
    end

    # Step 2: Add UUID foreign key columns
    # Users table (no foreign keys)
    
    # Tags table (no foreign keys)
    
    # Projects table
    add_column :projects, :owner_uuid, :uuid
    
    # Collaborations table
    add_column :collaborations, :project_uuid, :uuid
    add_column :collaborations, :user_uuid, :uuid
    
    # Collaboration Requests table
    add_column :collaboration_requests, :project_uuid, :uuid
    add_column :collaboration_requests, :user_uuid, :uuid
    
    # Comments table
    add_column :comments, :project_uuid, :uuid
    add_column :comments, :user_uuid, :uuid
    add_column :comments, :parent_uuid, :uuid
    
    # Funds table
    add_column :funds, :project_uuid, :uuid
    add_column :funds, :funder_uuid, :uuid
    
    # Messages table
    add_column :messages, :sender_uuid, :uuid
    add_column :messages, :receiver_uuid, :uuid
    add_column :messages, :project_uuid, :uuid
    
    # Project Stats table
    add_column :project_stats, :project_uuid, :uuid
    
    # Project Tags table
    add_column :project_tags, :project_uuid, :uuid
    add_column :project_tags, :tag_uuid, :uuid
    
    # Resources table
    add_column :resources, :project_uuid, :uuid
    add_column :resources, :added_by_uuid, :uuid
    
    # Votes table
    add_column :votes, :project_uuid, :uuid
    add_column :votes, :user_uuid, :uuid
    
    # User Tags table
    add_column :user_tags, :user_uuid, :uuid
    add_column :user_tags, :tag_uuid, :uuid
    
    # Audit Logs table
    add_column :audit_logs, :user_uuid, :uuid
    
    # Reports table
    add_column :reports, :reporter_uuid, :uuid
    add_column :reports, :resolved_by_uuid, :uuid
    
    # API Logs table (user_id is nullable, no FK needed)

    # Step 3: Populate UUID foreign keys from bigint IDs
    execute <<-SQL
      -- Projects
      UPDATE projects SET owner_uuid = users.uuid FROM users WHERE projects.owner_id = users.id;
      
      -- Collaborations
      UPDATE collaborations SET project_uuid = projects.uuid FROM projects WHERE collaborations.project_id = projects.id;
      UPDATE collaborations SET user_uuid = users.uuid FROM users WHERE collaborations.user_id = users.id;
      
      -- Collaboration Requests
      UPDATE collaboration_requests SET project_uuid = projects.uuid FROM projects WHERE collaboration_requests.project_id = projects.id;
      UPDATE collaboration_requests SET user_uuid = users.uuid FROM users WHERE collaboration_requests.user_id = users.id;
      
      -- Comments
      UPDATE comments SET project_uuid = projects.uuid FROM projects WHERE comments.project_id = projects.id;
      UPDATE comments SET user_uuid = users.uuid FROM users WHERE comments.user_id = users.id;
      UPDATE comments c1 SET parent_uuid = c2.uuid FROM comments c2 WHERE c1.parent_id = c2.id;
      
      -- Funds
      UPDATE funds SET project_uuid = projects.uuid FROM projects WHERE funds.project_id = projects.id;
      UPDATE funds SET funder_uuid = users.uuid FROM users WHERE funds.funder_id = users.id;
      
      -- Messages
      UPDATE messages SET sender_uuid = users.uuid FROM users WHERE messages.sender_id = users.id;
      UPDATE messages SET receiver_uuid = users.uuid FROM users WHERE messages.receiver_id = users.id;
      UPDATE messages SET project_uuid = projects.uuid FROM projects WHERE messages.project_id = projects.id;
      
      -- Project Stats
      UPDATE project_stats SET project_uuid = projects.uuid FROM projects WHERE project_stats.project_id = projects.id;
      
      -- Project Tags
      UPDATE project_tags SET project_uuid = projects.uuid FROM projects WHERE project_tags.project_id = projects.id;
      UPDATE project_tags SET tag_uuid = tags.uuid FROM tags WHERE project_tags.tag_id = tags.id;
      
      -- Resources
      UPDATE resources SET project_uuid = projects.uuid FROM projects WHERE resources.project_id = projects.id;
      UPDATE resources SET added_by_uuid = users.uuid FROM users WHERE resources.added_by_id = users.id;
      
      -- Votes
      UPDATE votes SET project_uuid = projects.uuid FROM projects WHERE votes.project_id = projects.id;
      UPDATE votes SET user_uuid = users.uuid FROM users WHERE votes.user_id = users.id;
      
      -- User Tags
      UPDATE user_tags SET user_uuid = users.uuid FROM users WHERE user_tags.user_id = users.id;
      UPDATE user_tags SET tag_uuid = tags.uuid FROM tags WHERE user_tags.tag_id = tags.id;
      
      -- Audit Logs
      UPDATE audit_logs SET user_uuid = users.uuid FROM users WHERE audit_logs.user_id = users.id;
      
      -- Reports
      UPDATE reports SET reporter_uuid = users.uuid FROM users WHERE reports.reporter_id = users.id;
      UPDATE reports r SET resolved_by_uuid = u.uuid FROM users u WHERE r.resolved_by_id = u.id;
    SQL

    # Step 4: Remove old foreign key constraints
    remove_foreign_key :audit_logs, :users if foreign_key_exists?(:audit_logs, :users)
    remove_foreign_key :collaboration_requests, :projects if foreign_key_exists?(:collaboration_requests, :projects)
    remove_foreign_key :collaboration_requests, :users if foreign_key_exists?(:collaboration_requests, :users)
    remove_foreign_key :collaborations, :projects if foreign_key_exists?(:collaborations, :projects)
    remove_foreign_key :collaborations, :users if foreign_key_exists?(:collaborations, :users)
    remove_foreign_key :comments, column: :parent_id if foreign_key_exists?(:comments, column: :parent_id)
    remove_foreign_key :comments, :projects if foreign_key_exists?(:comments, :projects)
    remove_foreign_key :comments, :users if foreign_key_exists?(:comments, :users)
    remove_foreign_key :funds, :projects if foreign_key_exists?(:funds, :projects)
    remove_foreign_key :funds, column: :funder_id if foreign_key_exists?(:funds, column: :funder_id)
    remove_foreign_key :messages, :projects if foreign_key_exists?(:messages, :projects)
    remove_foreign_key :messages, column: :receiver_id if foreign_key_exists?(:messages, column: :receiver_id)
    remove_foreign_key :messages, column: :sender_id if foreign_key_exists?(:messages, column: :sender_id)
    remove_foreign_key :project_stats, :projects if foreign_key_exists?(:project_stats, :projects)
    remove_foreign_key :project_tags, :projects if foreign_key_exists?(:project_tags, :projects)
    remove_foreign_key :project_tags, :tags if foreign_key_exists?(:project_tags, :tags)
    remove_foreign_key :projects, column: :owner_id if foreign_key_exists?(:projects, column: :owner_id)
    remove_foreign_key :reports, column: :reporter_id if foreign_key_exists?(:reports, column: :reporter_id)
    remove_foreign_key :reports, column: :resolved_by_id if foreign_key_exists?(:reports, column: :resolved_by_id)
    remove_foreign_key :resources, :projects if foreign_key_exists?(:resources, :projects)
    remove_foreign_key :resources, column: :added_by_id if foreign_key_exists?(:resources, column: :added_by_id)
    remove_foreign_key :user_tags, :tags if foreign_key_exists?(:user_tags, :tags)
    remove_foreign_key :user_tags, :users if foreign_key_exists?(:user_tags, :users)
    remove_foreign_key :votes, :projects if foreign_key_exists?(:votes, :projects)
    remove_foreign_key :votes, :users if foreign_key_exists?(:votes, :users)

    # Step 5: Remove old indexes on bigint columns
    remove_index :audit_logs, :user_id if index_exists?(:audit_logs, :user_id)
    remove_index :collaboration_requests, :project_id if index_exists?(:collaboration_requests, :project_id)
    remove_index :collaboration_requests, :user_id if index_exists?(:collaboration_requests, :user_id)
    remove_index :collaboration_requests, [:project_id, :user_id], name: "index_collab_requests_on_project_and_user" if index_exists?(:collaboration_requests, [:project_id, :user_id], name: "index_collab_requests_on_project_and_user")
    remove_index :collaborations, :project_id if index_exists?(:collaborations, :project_id)
    remove_index :collaborations, :user_id if index_exists?(:collaborations, :user_id)
    remove_index :comments, :parent_id if index_exists?(:comments, :parent_id)
    remove_index :comments, :project_id if index_exists?(:comments, :project_id)
    remove_index :comments, :user_id if index_exists?(:comments, :user_id)
    remove_index :funds, :funder_id if index_exists?(:funds, :funder_id)
    remove_index :funds, [:project_id, :funder_id] if index_exists?(:funds, [:project_id, :funder_id])
    remove_index :funds, :project_id if index_exists?(:funds, :project_id)
    remove_index :messages, :project_id if index_exists?(:messages, :project_id)
    remove_index :messages, :receiver_id if index_exists?(:messages, :receiver_id)
    remove_index :messages, [:sender_id, :receiver_id] if index_exists?(:messages, [:sender_id, :receiver_id])
    remove_index :messages, :sender_id if index_exists?(:messages, :sender_id)
    remove_index :project_stats, :project_id if index_exists?(:project_stats, :project_id)
    remove_index :project_tags, :project_id if index_exists?(:project_tags, :project_id)
    remove_index :project_tags, :tag_id if index_exists?(:project_tags, :tag_id)
    remove_index :projects, :owner_id if index_exists?(:projects, :owner_id)
    remove_index :reports, [:reportable_type, :reportable_id], name: "index_reports_on_reportable" if index_exists?(:reports, [:reportable_type, :reportable_id], name: "index_reports_on_reportable")
    remove_index :reports, [:reportable_type, :reportable_id], name: "index_reports_on_reportable_type_and_reportable_id" if index_exists?(:reports, [:reportable_type, :reportable_id], name: "index_reports_on_reportable_type_and_reportable_id")
    remove_index :reports, :reporter_id if index_exists?(:reports, :reporter_id)
    remove_index :reports, :resolved_by_id if index_exists?(:reports, :resolved_by_id)
    remove_index :resources, :added_by_id if index_exists?(:resources, :added_by_id)
    remove_index :resources, :project_id if index_exists?(:resources, :project_id)
    remove_index :user_tags, :tag_id if index_exists?(:user_tags, :tag_id)
    remove_index :user_tags, [:user_id, :tag_id] if index_exists?(:user_tags, [:user_id, :tag_id])
    remove_index :user_tags, :user_id if index_exists?(:user_tags, :user_id)
    remove_index :votes, :project_id if index_exists?(:votes, :project_id)
    remove_index :votes, [:user_id, :project_id] if index_exists?(:votes, [:user_id, :project_id])
    remove_index :votes, :user_id if index_exists?(:votes, :user_id)

    # Step 6: Remove old bigint ID and foreign key columns
    remove_column :audit_logs, :user_id
    remove_column :collaboration_requests, :project_id
    remove_column :collaboration_requests, :user_id
    remove_column :collaborations, :project_id
    remove_column :collaborations, :user_id
    remove_column :comments, :parent_id
    remove_column :comments, :project_id
    remove_column :comments, :user_id
    remove_column :funds, :funder_id
    remove_column :funds, :project_id
    remove_column :messages, :project_id
    remove_column :messages, :receiver_id
    remove_column :messages, :sender_id
    remove_column :project_stats, :project_id
    remove_column :project_tags, :project_id
    remove_column :project_tags, :tag_id
    remove_column :projects, :owner_id
    remove_column :reports, :reporter_id
    remove_column :reports, :resolved_by_id
    remove_column :resources, :added_by_id
    remove_column :resources, :project_id
    remove_column :user_tags, :tag_id
    remove_column :user_tags, :user_id
    remove_column :votes, :project_id
    remove_column :votes, :user_id

    # Step 7: Rename uuid column to id and UUID FK columns
    tables.each do |table|
      remove_column table, :id
      rename_column table, :uuid, :id
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id);"
    end

    # Rename UUID foreign key columns
    rename_column :projects, :owner_uuid, :owner_id
    rename_column :collaborations, :project_uuid, :project_id
    rename_column :collaborations, :user_uuid, :user_id
    rename_column :collaboration_requests, :project_uuid, :project_id
    rename_column :collaboration_requests, :user_uuid, :user_id
    rename_column :comments, :project_uuid, :project_id
    rename_column :comments, :user_uuid, :user_id
    rename_column :comments, :parent_uuid, :parent_id
    rename_column :funds, :project_uuid, :project_id
    rename_column :funds, :funder_uuid, :funder_id
    rename_column :messages, :sender_uuid, :sender_id
    rename_column :messages, :receiver_uuid, :receiver_id
    rename_column :messages, :project_uuid, :project_id
    rename_column :project_stats, :project_uuid, :project_id
    rename_column :project_tags, :project_uuid, :project_id
    rename_column :project_tags, :tag_uuid, :tag_id
    rename_column :resources, :project_uuid, :project_id
    rename_column :resources, :added_by_uuid, :added_by_id
    rename_column :votes, :project_uuid, :project_id
    rename_column :votes, :user_uuid, :user_id
    rename_column :user_tags, :user_uuid, :user_id
    rename_column :user_tags, :tag_uuid, :tag_id
    rename_column :audit_logs, :user_uuid, :user_id
    rename_column :reports, :reporter_uuid, :reporter_id
    rename_column :reports, :resolved_by_uuid, :resolved_by_id

    # Step 8: Set NOT NULL constraints on required foreign keys
    change_column_null :projects, :owner_id, false
    change_column_null :collaborations, :project_id, false
    change_column_null :collaborations, :user_id, false
    change_column_null :collaboration_requests, :project_id, false
    change_column_null :collaboration_requests, :user_id, false
    change_column_null :comments, :project_id, false
    change_column_null :comments, :user_id, false
    change_column_null :funds, :project_id, false
    change_column_null :funds, :funder_id, false
    change_column_null :messages, :sender_id, false
    change_column_null :messages, :receiver_id, false
    change_column_null :project_stats, :project_id, false
    change_column_null :project_tags, :project_id, false
    change_column_null :project_tags, :tag_id, false
    change_column_null :resources, :project_id, false
    change_column_null :resources, :added_by_id, false
    change_column_null :votes, :project_id, false
    change_column_null :votes, :user_id, false
    change_column_null :user_tags, :user_id, false
    change_column_null :user_tags, :tag_id, false
    change_column_null :audit_logs, :user_id, false
    change_column_null :reports, :reporter_id, false

    # Step 9: Re-create indexes
    add_index :audit_logs, :user_id
    add_index :collaboration_requests, :project_id
    add_index :collaboration_requests, :user_id
    add_index :collaboration_requests, [:project_id, :user_id], unique: true, name: "index_collab_requests_on_project_and_user"
    add_index :collaborations, :project_id
    add_index :collaborations, :user_id
    add_index :comments, :parent_id
    add_index :comments, :project_id
    add_index :comments, :user_id
    add_index :funds, :funder_id
    add_index :funds, [:project_id, :funder_id]
    add_index :funds, :project_id
    add_index :messages, :project_id
    add_index :messages, :receiver_id
    add_index :messages, [:sender_id, :receiver_id]
    add_index :messages, :sender_id
    add_index :project_stats, :project_id
    add_index :project_tags, :project_id
    add_index :project_tags, :tag_id
    add_index :projects, :owner_id
    add_index :reports, [:reportable_type, :reportable_id], name: "index_reports_on_reportable"
    add_index :reports, :reporter_id
    add_index :reports, :resolved_by_id
    add_index :resources, :added_by_id
    add_index :resources, :project_id
    add_index :user_tags, :tag_id
    add_index :user_tags, [:user_id, :tag_id], unique: true
    add_index :user_tags, :user_id
    add_index :votes, :project_id
    add_index :votes, [:user_id, :project_id], unique: true
    add_index :votes, :user_id

    # Step 10: Re-create foreign key constraints
    add_foreign_key :audit_logs, :users
    add_foreign_key :collaboration_requests, :projects
    add_foreign_key :collaboration_requests, :users
    add_foreign_key :collaborations, :projects
    add_foreign_key :collaborations, :users
    add_foreign_key :comments, :comments, column: :parent_id
    add_foreign_key :comments, :projects
    add_foreign_key :comments, :users
    add_foreign_key :funds, :projects
    add_foreign_key :funds, :users, column: :funder_id
    add_foreign_key :messages, :projects
    add_foreign_key :messages, :users, column: :receiver_id
    add_foreign_key :messages, :users, column: :sender_id
    add_foreign_key :project_stats, :projects
    add_foreign_key :project_tags, :projects
    add_foreign_key :project_tags, :tags
    add_foreign_key :projects, :users, column: :owner_id
    add_foreign_key :reports, :users, column: :reporter_id
    add_foreign_key :reports, :users, column: :resolved_by_id
    add_foreign_key :resources, :projects
    add_foreign_key :resources, :users, column: :added_by_id
    add_foreign_key :user_tags, :tags
    add_foreign_key :user_tags, :users
    add_foreign_key :votes, :projects
    add_foreign_key :votes, :users
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot reverse UUID conversion - data would be lost"
  end
end
