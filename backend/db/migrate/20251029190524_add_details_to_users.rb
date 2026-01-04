class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :country, :string
    add_column :users, :university, :string
    add_column :users, :department, :string
    add_column :users, :professional_role, :string
  end
end
