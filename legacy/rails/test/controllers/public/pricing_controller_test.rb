require "test_helper"

class Public::PricingControllerTest < ActionDispatch::IntegrationTest
  test "pricing makes paid plan availability explicit" do
    get public_pricing_url
    assert_response :success
    assert_select "p", text: /O plano pago ainda não está disponível/
  end
end
