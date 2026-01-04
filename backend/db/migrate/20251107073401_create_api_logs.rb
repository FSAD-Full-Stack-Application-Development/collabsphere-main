class CreateApiLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :api_logs do |t|
      t.string :ip_address
      t.string :user_agent
      t.string :request_method
      t.string :request_path
      t.text :request_params
      t.integer :response_status
      t.text :response_message
      t.integer :user_id
      t.float :duration

      t.timestamps
    end

    add_index :api_logs, :ip_address
    add_index :api_logs, :request_method
    add_index :api_logs, :request_path
    add_index :api_logs, :response_status
    add_index :api_logs, :user_id
    add_index :api_logs, :created_at
  end
end
