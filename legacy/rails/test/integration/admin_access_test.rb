require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  # These are test-only credentials. They are unrelated to the local admin secret.
  ADMIN_TEST_PASSWORD = "OnlyForTests-Admin-Password-123456!"

  test "anonymous visitors must sign in before accessing administration" do
    get admin_root_url
    assert_redirected_to new_user_session_url
    get admin_users_url
    assert_redirected_to new_user_session_url
  end

  test "regular users cannot access either administrative page" do
    sign_in users(:one)
    get admin_root_url
    assert_response :forbidden
    get admin_users_url
    assert_response :forbidden
  end

  test "administrator sees account data without financial details" do
    admin = users(:one)
    admin.update!(admin: true, password: ADMIN_TEST_PASSWORD)
    transactions(:two).update!(description: "Despesa particular que não deve aparecer")
    sign_in admin
    get admin_root_url
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "a[href=?]", admin_users_path
    get admin_users_url
    assert_response :success
    assert_select "td", text: users(:two).email
    assert_not_includes response.body, "Despesa particular que não deve aparecer"
    assert_not_includes response.body, admin.encrypted_password
    assert_select "form", count: 0
  end

  test "admin login redirects to administrative dashboard" do
    admin = users(:one)
    admin.update!(admin: true, password: ADMIN_TEST_PASSWORD)
    post user_session_url, params: { user: { email: admin.email, password: ADMIN_TEST_PASSWORD } }
    assert_redirected_to admin_root_url
  end

  test "registration cannot grant administrative privileges" do
    post user_registration_url, params: {
      user: { email: "normal@example.test", password: "RegularPassword123!", password_confirmation: "RegularPassword123!", admin: true, role: "admin" }
    }
    user = User.find_by!(email: "normal@example.test")
    assert_not user.admin?
  end

  test "account update cannot promote a regular user" do
    user = users(:one)
    sign_in user
    put user_registration_url, params: { user: { current_password: "Password123!", name: "Novo nome", admin: true, role: "admin" } }
    assert_equal "Novo nome", user.reload.name
    assert_not user.admin?
  end

  test "ordinary navigation does not expose administrative links" do
    sign_in users(:one)
    get users_dashboard_url
    assert_response :success
    assert_select "a[href=?]", admin_root_path, count: 0
  end

  test "administrative users list is paginated and page is bounded" do
    users(:one).update!(admin: true)
    27.times do |index|
      User.create!(email: "paged-#{index}@example.test", password: "RegularPassword123!")
    end
    sign_in users(:one)
    get admin_users_url
    assert_select "tbody tr", count: 25
    assert_select "a[href=?]", admin_users_path(page: 2)
    get admin_users_url(page: 999999999)
    assert_response :success
    assert_select "tbody tr", count: 4
  end

  test "repeated wrong passwords lock account and time allows login again" do
    user = users(:one)
    User.maximum_attempts.times do
      post user_session_url, params: { user: { email: user.email, password: "WrongPassword!" } }
    end
    assert user.reload.access_locked?
    post user_session_url, params: { user: { email: user.email, password: "Password123!" } }
    get users_dashboard_url
    assert_redirected_to new_user_session_url
    travel User.unlock_in + 1.second do
      post user_session_url, params: { user: { email: user.email, password: "Password123!" } }
      assert_redirected_to users_dashboard_url
    end
  end

  test "an administrator cannot reset password to a weak value" do
    admin = users(:one)
    admin.update!(admin: true)
    token = admin.send_reset_password_instructions
    put user_password_url, params: { user: { reset_password_token: token, password: "Weak123!", password_confirmation: "Weak123!" } }
    assert_response :unprocessable_content
    assert admin.reload.valid_password?("Password123!")
  end
end
