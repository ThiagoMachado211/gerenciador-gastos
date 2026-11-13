require "test_helper"

class Users::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get users_analytics_url
    assert_redirected_to new_user_session_url
  end

  test "analytics redirects to dashboard" do
    sign_in users(:one)
    get users_analytics_url
    assert_redirected_to users_dashboard_url
  end
end
