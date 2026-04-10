require "test_helper"

class Public::PricingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get public_pricing_index_url
    assert_response :success
  end
end
