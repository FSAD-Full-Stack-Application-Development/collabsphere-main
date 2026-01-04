class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :age, :integer
    add_column :users, :occupation, :string
    add_column :users, :short_term_goals, :text
    add_column :users, :long_term_goals, :text
    add_column :users, :immediate_questions, :text
    add_column :users, :computer_equipment, :string
    add_column :users, :connection_type, :string
  end
end
