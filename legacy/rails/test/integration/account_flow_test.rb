require "test_helper"

class AccountFlowTest < ActionDispatch::IntegrationTest
  test "registers user and opens dashboard" do
    assert_difference "User.count", 1 do
      post user_registration_url, params: {
        user: { name: "Carla", email: "carla@example.test", password: "Password123!", password_confirmation: "Password123!" }
      }
    end
    assert_redirected_to users_dashboard_url
    follow_redirect!
    assert_response :success
  end

  test "logs in and logs out" do
    post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } }
    assert_redirected_to users_dashboard_url
    get users_dashboard_url
    assert_response :success
    delete destroy_user_session_url
    get users_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "resets password using emailed token" do
    user = users(:one)
    assert_emails 1 do
      post user_password_url, params: { user: { email: user.email } }
    end
    assert user.reload.reset_password_token.present?

    mail = ActionMailer::Base.deliveries.last
    body = mail.html_part&.body&.decoded || mail.body.decoded
    token = body[/reset_password_token=([^"&\s<]+)/, 1]
    assert token.present?, "Reset email must contain the password reset token"
    put user_password_url, params: {
      user: { reset_password_token: token, password: "UpdatedPassword123!", password_confirmation: "UpdatedPassword123!" }
    }
    assert_redirected_to users_dashboard_url
    assert user.reload.valid_password?("UpdatedPassword123!")
    assert_nil user.reset_password_token
  end
end
