require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "does not accept payment events before integration is implemented" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/webhooks/stripe", method: :post)
    end
  end
end
