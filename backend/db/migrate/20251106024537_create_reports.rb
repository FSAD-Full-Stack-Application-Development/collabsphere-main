class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.string :reason, null: false
      t.text :description
      t.string :status, default: 'pending', null: false
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end
    
    add_index :reports, :status
    add_index :reports, [:reportable_type, :reportable_id]
  end
end
