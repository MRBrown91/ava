require "test_helper"

class MigrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get migrations_path
    assert_response :success
  end

  test "should get new" do
    get new_migration_path
    assert_response :success
  end

  test "should get show" do
    get migration_path(data_migrations(:one))
    assert_response :success
  end
end
