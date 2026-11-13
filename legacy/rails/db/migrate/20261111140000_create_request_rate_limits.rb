class CreateRequestRateLimits < ActiveRecord::Migration[8.1]
  def change
    create_table :request_rate_limits, id: :string, primary_key: :key do |t|
      t.integer :requests_count, null: false, default: 0
      t.datetime :expires_at, null: false
    end
    add_index :request_rate_limits, :expires_at
  end
end
