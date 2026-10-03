require "test_helper"

class MigrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get migrations_index_url
    assert_response :success
  end

  test "should get show" do
    get migrations_show_url
    assert_response :success
  end

  test "should get create" do
    get migrations_create_url
    assert_response :success
  end
end
