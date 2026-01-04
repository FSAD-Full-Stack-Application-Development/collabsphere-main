class CreateResources < ActiveRecord::Migration[8.0]
  def change
    create_table :resources do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :url
      t.references :added_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
