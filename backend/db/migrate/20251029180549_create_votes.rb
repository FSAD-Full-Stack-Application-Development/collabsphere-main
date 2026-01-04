class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :vote_type
      t.datetime :voted_at

      t.timestamps
    end
  end
end
