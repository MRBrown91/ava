require "test_helper"

class TransformDataMigrationJobTest < ActiveJob::TestCase
  setup do
    @data_migration = DataMigration.create!(source_type: "csv_upload", status: "pending")
  end

  test "create multiple chunks" do
    create_raw_rows(1..1200)

    TransformDataMigrationJob.perform_now(@data_migration.id)

    assert_enqueued_jobs 3, only: TransformDataMigrationChunkJob
    assert_enqueued_with job: TransformDataMigrationChunkJob, args: [ @data_migration.id, 1, 500 ]
    assert_enqueued_with job: TransformDataMigrationChunkJob, args: [ @data_migration.id, 501, 1000 ]
    assert_enqueued_with job: TransformDataMigrationChunkJob, args: [ @data_migration.id, 1001, 1200 ]
  end

  test "create sing chunk" do
    create_raw_rows(1..20)

    TransformDataMigrationJob.perform_now(@data_migration.id)

    assert_enqueued_jobs 1, only: TransformDataMigrationChunkJob
    assert_enqueued_with job: TransformDataMigrationChunkJob, args: [ @data_migration.id, 1, 20 ]
  end

  test "metadata recorded on failure" do
    create_raw_rows(1..1)

    TransformDataMigrationJob.perform_now(@data_migration.id)

    assert_equal "transforming", @data_migration.reload.status
    assert_not_nil @data_migration.transform_started_at
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
