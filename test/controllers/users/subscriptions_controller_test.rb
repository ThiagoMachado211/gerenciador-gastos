require "test_helper"

class Users::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get users_subscriptions_show_url
    assert_response :success
  end
end
