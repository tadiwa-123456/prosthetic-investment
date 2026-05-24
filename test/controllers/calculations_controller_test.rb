require "test_helper"

class CalculationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get calculations_index_url
    assert_response :success
  end
end
