class CreateFunds < ActiveRecord::Migration[8.0]
  def change
    create_table :funds do |t|
      t.references :project, null: false, foreign_key: true
      t.references :funder, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2
      t.datetime :funded_at

      t.timestamps
    end
  end
end
