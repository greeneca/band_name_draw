require 'test_helper'

class DrawNameControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get draw_name_index_url
    assert_response :success
  end

end
