class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :credit_card, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :kind
      t.string :description
      t.date :occurred_on
      t.integer :installments_count

      t.timestamps
    end
  end
end
