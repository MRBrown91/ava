require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get patients_path
    assert_response :success
  end

  test "should get show" do
    get patient_path(patients(:one))
    assert_response :success
  end
end
