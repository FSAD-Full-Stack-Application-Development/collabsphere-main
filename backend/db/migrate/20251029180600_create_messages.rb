class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.references :project, foreign_key: true
      t.text :content
      t.datetime :sent_at
      t.boolean :is_read, default: false

      t.timestamps
    end
  end
end
