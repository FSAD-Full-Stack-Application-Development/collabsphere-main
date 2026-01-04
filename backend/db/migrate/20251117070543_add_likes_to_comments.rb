class AddLikesToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :likes, :integer
  end
end
