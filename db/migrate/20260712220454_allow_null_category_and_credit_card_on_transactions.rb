class AllowNullCategoryAndCreditCardOnTransactions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :transactions, :category_id, true
    change_column_null :transactions, :credit_card_id, true
  end
end