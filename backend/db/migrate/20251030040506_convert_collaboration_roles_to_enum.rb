class ConvertCollaborationRolesToEnum < ActiveRecord::Migration[8.0]
  def up
    # Convert project_role from string to integer for enum
    add_column :collaborations, :project_role_temp, :integer, default: 1
    
    # Map existing values to enum (owner, member, viewer)
    Collaboration.reset_column_information
    Collaboration.find_each do |collab|
      case collab.project_role
      when 'owner'
        collab.update_column(:project_role_temp, 0) # owner
      when 'collaborator', 'vc'
        collab.update_column(:project_role_temp, 1) # member
      else
        collab.update_column(:project_role_temp, 1) # default to member
      end
    end
    
    # Remove old column and rename new one
    remove_column :collaborations, :project_role
    rename_column :collaborations, :project_role_temp, :project_role
    
    # Remove permission_level (not needed with simplified roles)
    remove_column :collaborations, :permission_level if column_exists?(:collaborations, :permission_level)
    
    # Remove role_name if it exists (duplicate)
    remove_column :collaborations, :role_name if column_exists?(:collaborations, :role_name)
  end
  
  def down
    # Revert back to string
    add_column :collaborations, :project_role_temp, :string
    
    Collaboration.reset_column_information
    Collaboration.find_each do |collab|
      role_string = case collab.project_role
                    when 0 then 'owner'
                    when 1 then 'member'
                    when 2 then 'viewer'
                    else 'member'
                    end
      collab.update_column(:project_role_temp, role_string)
    end
    
    remove_column :collaborations, :project_role
    rename_column :collaborations, :project_role_temp, :project_role
    
    # Restore permission_level
    add_column :collaborations, :permission_level, :string
  end
end
