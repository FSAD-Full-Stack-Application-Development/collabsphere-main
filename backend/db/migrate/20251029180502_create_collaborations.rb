class CreateCollaborations < ActiveRecord::Migration[8.0]
  def change
    create_table :collaborations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :project_role
      t.string :permission_level

      t.timestamps
    end
  end
end
