class CreateProjectStats < ActiveRecord::Migration[8.0]
  def change
    create_table :project_stats do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :total_views
      t.integer :total_votes
      t.integer :total_comments
      t.datetime :last_updated

      t.timestamps
    end
  end
end
