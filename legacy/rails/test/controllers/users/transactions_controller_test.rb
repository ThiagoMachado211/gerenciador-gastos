require "test_helper"

class Users::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup { post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } } }

  test "creates a transaction without optional associations" do
    assert_difference "users(:one).transactions.count", 1 do
      post users_transactions_url, params: { transaction: valid_attributes }
    end
    assert_redirected_to users_transactions_url
  end

  test "rejects another users category and card on creation" do
    assert_no_difference "Transaction.count" do
      post users_transactions_url, params: {
        transaction: valid_attributes.merge(category_id: categories(:two).id, credit_card_id: credit_cards(:two).id)
      }
    end
    assert_response :unprocessable_entity
  end

  test "cannot change or delete another users transaction" do
    transaction = transactions(:two)
    patch users_transaction_url(transaction), params: { transaction: { amount_cents: 9900 } }
    assert_response :not_found
    assert_equal 1, transaction.reload.amount_cents
    assert_no_difference "Transaction.count" do
      delete users_transaction_url(transaction)
    end
    assert_response :not_found
  end

  test "updates and deletes own transaction" do
    transaction = transactions(:one)
    patch users_transaction_url(transaction), params: { transaction: { amount_cents: 4500 } }
    assert_redirected_to users_transactions_url
    assert_equal 4500, transaction.reload.amount_cents
    assert_difference "Transaction.count", -1 do
      delete users_transaction_url(transaction)
    end
    assert_redirected_to users_transactions_url
  end

  private

  def valid_attributes
    { description: "Compra", amount_cents: 2500, kind: "expense", occurred_on: Date.current, installments_count: 1 }
  end
end
