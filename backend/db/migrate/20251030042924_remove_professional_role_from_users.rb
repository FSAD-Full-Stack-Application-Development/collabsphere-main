class RemoveProfessionalRoleFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :professional_role, :string if column_exists?(:users, :professional_role)
  end
end
