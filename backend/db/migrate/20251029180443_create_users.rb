class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :full_name
      t.string :email
      t.string :password_digest
      t.string :system_role
      t.text :bio
      t.string :avatar_url

      t.timestamps
    end
  end
end
