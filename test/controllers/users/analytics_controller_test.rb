require "test_helper"

class Users::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get users_analytics_index_url
    assert_response :success
  end
end
