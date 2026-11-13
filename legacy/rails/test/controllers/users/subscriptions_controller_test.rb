require "test_helper"

class Users::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get users_subscription_url
    assert_redirected_to new_user_session_url
  end

  test "shows free plan without enabling payment" do
    sign_in users(:one)
    get users_subscription_url
    assert_response :success
    assert_select "button[disabled]", text: /Upgrade em breve/
  end

  test "does not expose unimplemented billing actions" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/subscription", method: :post)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/subscription", method: :delete)
    end
  end
end
