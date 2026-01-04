class AddStatusToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :resources, :status, :string, default: 'pending'
  end
end
