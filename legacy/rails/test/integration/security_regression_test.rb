require "test_helper"

class SecurityRegressionTest < ActionDispatch::IntegrationTest
  test "anonymous visitors cannot read private financial pages" do
    [ users_dashboard_url, users_transactions_url, users_categories_url, users_credit_cards_url, users_subscription_url ].each do |url|
      get url
      assert_redirected_to new_user_session_url
    end
  end

  test "anonymous visitors cannot create financial records" do
    assert_no_difference [ "Transaction.count", "Category.count", "CreditCard.count" ] do
      post users_transactions_url, params: { transaction: transaction_attributes }
      assert_redirected_to new_user_session_url
      post users_categories_url, params: { category: { name: "Unauthorized" } }
      assert_redirected_to new_user_session_url
      post users_credit_cards_url, params: { credit_card: { name: "Unauthorized", limit_cents: 100, closing_day: 1, due_day: 10 } }
      assert_redirected_to new_user_session_url
    end
  end

  test "edit forms do not disclose another accounts records" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    [ edit_users_transaction_url(transactions(:two)), edit_users_category_url(categories(:two)), edit_users_credit_card_url(credit_cards(:two)) ].each do |url|
      get url
      assert_response :not_found
    end
  end

  test "transaction creation ignores forged ownership" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    assert_difference "users(:one).transactions.count", 1 do
      assert_no_difference "users(:two).transactions.count" do
        post users_transactions_url, params: { transaction: transaction_attributes.merge(user_id: users(:two).id) }
      end
    end
    assert_redirected_to users_transactions_url
  end

  test "transaction update rejects foreign category and card without persisting changes" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    transaction = transactions(:one)
    original = transaction.attributes
    patch users_transaction_url(transaction), params: {
      transaction: { category_id: categories(:two).id, credit_card_id: credit_cards(:two).id, amount_cents: 9900 }
    }
    assert_response :unprocessable_content
    assert_equal original, transaction.reload.attributes
  end

  test "stored script payloads are escaped in financial pages and chart attributes" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    payload = %q{<script>alert("security-test")</script>}
    users(:one).update!(name: payload)
    categories(:one).update!(name: payload)
    transactions(:one).update!(description: payload, kind: "expense", occurred_on: Date.current)
    [ users_dashboard_url, users_transactions_url, users_categories_url ].each do |url|
      get url
      assert_response :success
      assert_not_includes response.body, payload
      assert_includes response.body, "&lt;script&gt;"
    end
  end

  test "financial writes require a CSRF token when forgery protection is enabled" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    previous = ActionController::Base.allow_forgery_protection
    begin
      ActionController::Base.allow_forgery_protection = true
      assert_no_difference "Transaction.count" do
        post users_transactions_url, params: { transaction: transaction_attributes }
      end
      assert_response :unprocessable_content
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end

  private

  def transaction_attributes
    { description: "Security regression", kind: "expense", amount_cents: 100, occurred_on: Date.current, installments_count: 1 }
  end
end
