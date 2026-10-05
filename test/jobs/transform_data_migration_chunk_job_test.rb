require "test_helper"

class TransformDataMigrationChunkJobTest < ActiveJob::TestCase
  setup do
    @data_migration = DataMigration.create!(source_type: "csv_upload", status: "transforming")
  end

  test "tranform only target rows" do
    create_raw_rows(1..3)

    TransformDataMigrationChunkJob.perform_now(@data_migration.id, 1, 2)

    assert_equal [ 1, 2 ], TransformedPatientDatum.where(data_migration_id: @data_migration.id).order(:row_number).pluck(:row_number)
  end

  test "transform valid row" do
    create_raw_rows(1..1, health_identifier: " 123456 ", health_identifier_province: "Alberta")

    TransformDataMigrationChunkJob.perform_now(@data_migration.id, 1, 1)

    transformed = TransformedPatientDatum.find_by(data_migration_id: @data_migration.id, row_number: 1)
    assert_equal "valid", transformed.transformation_status
    assert_nil transformed.transformation_error
    assert_equal "123456", transformed.patient_health_identifier_number
    assert_equal "AB", transformed.patient_health_identifier_number_province
  end

  test "transform invalid row" do
    create_raw_rows(1..1, health_identifier: nil, health_identifier_province: "ON")

    TransformDataMigrationChunkJob.perform_now(@data_migration.id, 1, 1)

    transformed = TransformedPatientDatum.find_by(data_migration_id: @data_migration.id, row_number: 1)
    assert_equal "invalid", transformed.transformation_status
    assert_equal "Health identifier is required", transformed.transformation_error
    assert_nil transformed.patient_health_identifier_number
    assert_equal "ON", transformed.patient_health_identifier_number_province
  end

  test "increment counter on transform" do
    create_raw_rows(1..3)

    TransformDataMigrationChunkJob.perform_now(@data_migration.id, 1, 2)
    assert_equal 2, @data_migration.reload.rows_transformed

    TransformDataMigrationChunkJob.perform_now(@data_migration.id, 3, 3)
    assert_equal 3, @data_migration.reload.rows_transformed
  end

  private

  def create_raw_rows(rows, health_identifier: "123456", health_identifier_province: "BC")
    now = Time.current
    RawPatientDatum.insert_all(rows.map do |row_number|
      {
        data_migration_id: @data_migration.id,
        row_number: row_number,
        health_identifier: health_identifier,
        health_identifier_province: health_identifier_province,
        first_name: "Matthew",
        last_name: "Brown",
        address_1: "2237 Sun Valley Dr.",
        address_city: "Nanaimo",
        address_province: "British Columbia",
        address_postal_code: "V9T6E8",
        date_of_birth: "1988-04-05",
        sex: "Male",
        source_hash: "raw_hash_#{row_number}",
        created_at: now
      }
    end)
  end
end
