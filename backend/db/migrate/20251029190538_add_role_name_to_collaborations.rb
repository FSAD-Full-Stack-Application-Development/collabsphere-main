class AddRoleNameToCollaborations < ActiveRecord::Migration[8.0]
  def change
    add_column :collaborations, :role_name, :string
  end
end
