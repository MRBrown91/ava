require "test_helper"

module Migrations
  class TransformServiceTest < ActiveSupport::TestCase
    setup do
      @raw_row = {
        id: 17,
        row_number: 9,
        health_identifier: " 123456 ",
        health_identifier_province: "bc",
        first_name: "  Matthew ",
        last_name: "Brown",
        middle_name: "Tommy    Lee",
        phone: "1(250) 555-1234",
        email: "  mrb.bc.ca@OutlOok.COM ",
        address_1: "2237 Sun Valley Drive.",
        address_2: nil,
        address_city: "nanaimo",
        address_province: "British columbia",
        address_postal_code: "vmt1a1",
        date_of_birth: "1988-04-05",
        sex: "Male",
        source_hash: "asdf1234zxcv"
      }

      @raw_invalid_row = @raw_row.merge(
        health_identifier: nil,
        health_identifier_province: "XX"
        )
    end

    test "transfrom valid patient" do
      result = TransformService.transform_patient(7, @raw_row, Time.current)

      assert_equal "valid", result[:transformation_status]
      assert_nil result[:transformation_error]
      assert_equal 7, result[:data_migration_id]
      assert_equal 17, result[:raw_patient_data_id]
      assert_equal 9, result[:row_number]
      assert_equal "asdf1234zxcv", result[:source_hash]
      assert_equal "123456", result[:patient_health_identifier_number]
      assert_equal "BC", result[:patient_health_identifier_number_province]
      assert_equal "Matthew", result[:first_name]
      assert_equal "Brown", result[:last_name]
      assert_equal "Tommy Lee", result[:middle_name]
      assert_equal "2505551234", result[:phone]
      assert_equal "mrb.bc.ca@outlook.com", result[:email]
      assert_equal Date.new(1988, 4, 5), result[:dob]
      assert_equal "M", result[:sex]
      assert_equal "2237 SUN VALLEY DR", result[:address_line_1]
      assert_equal "NANAIMO", result[:city]
      assert_equal "BC", result[:province]
      assert_equal "VMT 1A1", result[:postal_code]
    end

    test "transfrom invalid patient" do
      result = TransformService.transform_patient(1, @raw_invalid_row, Time.current)

      assert_equal "invalid", result[:transformation_status]
      assert_equal "Health identifier is required; Health identifier province is invalid", result[:transformation_error]
    end

    test "hash_address" do
      result = TransformService.transform_patient(1, @raw_row, Time.current)

      assert_equal 64, result[:address_target_hash].length
      assert_equal TransformService.hash_address("2237 SUN VALLEY DR", nil, "NANAIMO", "BC", "VMT 1A1"), result[:address_target_hash]
    end

    test "normalize_province" do
      {
        "ALBERTA" => "AB",
        "British Columbia" => "BC",
        "Newfoundland and Labrador" => "NL",
        "ON" => "ON",
        "XX" => "XX",
        nil => nil,
        "" => ""
      }.each do |input, expected|
        assert_normalizes TransformService.normalize_province(input), expected
      end
    end

    test "normalize_phone" do
      {
        "(613) 555-1234" => "6135551234",
        "1-613-555-1234" => "6135551234",
        "555-1234" => "5551234",
        "n/a" => nil,
        "12345" => nil,
        nil => nil
      }.each do |input, expected|
        assert_normalizes TransformService.normalize_phone(input), expected
      end
    end

    test "normalize_sex" do
      {
        "MALE" => "M",
        "MAN" => "M",
        "FEMALE" => "F",
        "WOMAN" => "F",
        "NON-BINARY" => "NB",
        "N.B." => "NB",
        nil => "UKN",
        "something else" => "UKN"
      }.each do |input, expected|
        assert_normalizes TransformService.normalize_sex(input), expected
      end
    end

    test "normalize_health_identifier" do
      {
        "0" => "0",
        " 12345 " => "12345",
        "12A" => nil,
        "" => nil,
        "003" => "003",
        nil => nil
      }.each do |input, expected|
        assert_normalizes TransformService.normalize_health_identifier(input), expected
      end
    end

    private

    def assert_normalizes(actual, expected)
      expected.nil? ? assert_nil(actual) : assert_equal(expected, actual)
    end
  end
end
