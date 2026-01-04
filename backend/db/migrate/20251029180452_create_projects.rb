class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.text :description
      t.string :status
      t.string :visibility
      t.boolean :show_funds

      t.timestamps
    end
  end
end
