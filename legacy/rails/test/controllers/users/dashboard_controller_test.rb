require "test_helper"

class Users::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get users_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "signed in user can open dashboard" do
    sign_in users(:one)
    get users_dashboard_url
    assert_response :success
  end
end
