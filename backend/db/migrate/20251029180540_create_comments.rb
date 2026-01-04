class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :comments }
      t.text :content

      t.timestamps
    end
  end
end
