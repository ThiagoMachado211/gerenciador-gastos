require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "health check is public" do
    get rails_health_check_url
    assert_response :success
  end
end
