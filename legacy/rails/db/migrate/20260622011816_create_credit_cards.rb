class CreateCreditCards < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.integer :limit_cents
      t.integer :closing_day
      t.integer :due_day

      t.timestamps
    end
  end
end
