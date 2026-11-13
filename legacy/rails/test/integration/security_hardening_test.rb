require "test_helper"

class SecurityHardeningTest < ActionDispatch::IntegrationTest
  test "password recovery gives the same public response for unknown accounts" do
    post user_password_url, params: { user: { email: users(:one).email } }
    known = [ response.status, response.location, flash[:notice] ]
    post user_password_url, params: { user: { email: "unknown@example.test" } }
    assert_equal known, [ response.status, response.location, flash[:notice] ]
  end

  test "password recovery limits email across different IPs" do
    3.times do |index|
      post user_password_url, params: { user: { email: " ANA@example.test " } }, env: { "REMOTE_ADDR" => "198.51.100.#{index + 1}" }
      assert_response :see_other
    end
    assert_no_emails do
      post user_password_url, params: { user: { email: users(:one).email } }, env: { "REMOTE_ADDR" => "198.51.100.99" }
    end
    assert_response :too_many_requests
    assert_equal "900", response.headers["Retry-After"]
  end

  test "login limits requests even when submitted emails vary" do
    30.times do |index|
      post user_session_url, params: { user: { email: "unknown-#{index}@example.test", password: "IncorrectPassword!" } }
      assert_response :unprocessable_content
    end
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    assert_response :too_many_requests
  end

  test "signup limits account creation from one IP" do
    5.times do |index|
      post user_registration_url, params: { user: { email: "signup-#{index}@example.test", password: "short", password_confirmation: "short" } }
      assert_response :unprocessable_content
    end
    assert_no_difference "User.count" do
      post user_registration_url, params: { user: { email: "extra@example.test", password: "RegularPassword123!", password_confirmation: "RegularPassword123!" } }
    end
    assert_response :too_many_requests
  end

  test "invalid foreign keys and excessive amounts produce validation responses" do
    sign_in users(:one)
    attributes = { description: "Invalid input", kind: "expense", amount_cents: 100, occurred_on: Date.current, installments_count: 1 }
    [ { category_id: Category.maximum(:id) + 1 }, { credit_card_id: CreditCard.maximum(:id) + 1 }, { amount_cents: 2_147_483_648 } ].each do |invalid|
      assert_no_difference "Transaction.count" do
        post users_transactions_url, params: { transaction: attributes.merge(invalid) }
      end
      assert_response :unprocessable_content
    end
  end

  test "financial pages cannot be cached and scripts require a fresh nonce" do
    sign_in users(:one)
    get users_dashboard_url
    assert_equal "no-store", response.headers["Cache-Control"]
    policy = response.headers.fetch("Content-Security-Policy")
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    nonce = policy[/script-src[^;]*'nonce-([^']+)'/, 1]
    assert nonce.present?
    assert_select "script[type=importmap][nonce=?]", nonce
    get users_dashboard_url
    assert_not_equal nonce, response.headers.fetch("Content-Security-Policy")[/script-src[^;]*'nonce-([^']+)'/, 1]
  end

  test "transaction pagination preserves totals over the entire history" do
    sign_in users(:one)
    users(:one).transactions.destroy_all
    27.times do |index|
      users(:one).transactions.create!(description: "Entry #{index}", kind: "income", amount_cents: 100, occurred_on: Date.current, installments_count: 1)
    end
    get users_transactions_url
    assert_response :success
    assert_select ".resource-item", count: 25
    assert_select "a[href=?]", users_transactions_path(page: 2)
    assert_includes response.body, "27 movimentação(ões)"
    assert_includes response.body, "27,00"
    get users_transactions_url(page: 999999)
    assert_response :success
    assert_select ".resource-item", count: 2
    get users_transactions_url(page: [ "invalid" ])
    assert_response :success
  end
end
