require "test_helper"

class Public::HomeControllerTest < ActionDispatch::IntegrationTest
  test "home is public" do
    get root_url
    assert_response :success
  end
end
