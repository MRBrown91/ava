require "test_helper"

class TransformDataMigrationSuccessJobTest < ActiveJob::TestCase
  setup do
    @data_migration = DataMigration.create!(
      source_type: "csv_upload",
      status: "transforming",
      transform_started_at: 1.minute.ago
    )

    @batch = SolidQueue::Batch.create!(
      metadata: {
        "data_migration_id" => @data_migration.id,
        "continue_to_next_stage" => true
      },
      total_jobs: 4,
      finished_at: Time.current
    )
  end

  test "metadata recorded on success" do
    create_transformed_row(1, 111)

    job = TransformDataMigrationSuccessJob.new
    job.batch_id = @batch.id
    job.perform_now

    assert_equal "transformation_complete", @data_migration.reload.status
    assert_nil @data_migration.completed_at
    assert_not_nil @data_migration.transform_completed_at
    assert_operator @data_migration.transform_time_ms, :>, 0
  end

  test "deduplicate on success" do
    row_1 = create_transformed_row(1, 111)
    row_2 = create_transformed_row(2, 111)
    row_3 = create_transformed_row(3, 222)

    job = TransformDataMigrationSuccessJob.new
    job.batch_id = @batch.id
    job.perform_now

    assert_equal "invalid", row_1.reload.transformation_status
    assert_equal "Duplicate health identifier and province", row_1.transformation_error
    assert_equal "valid", row_2.reload.transformation_status
    assert_equal "valid", row_3.reload.transformation_status
  end

  test "enqueues load job when continuing and prerequisite passes (transform rows exist)" do
    create_transformed_row(1, 111)

    job = TransformDataMigrationSuccessJob.new
    job.batch_id = @batch.id
    job.perform_now

    assert_enqueued_with job: LoadDataMigrationJob, args: [ @data_migration.id ]
  end

  test "does not enqueues load job when not continuing and prerequisite passes (transform rows exist)" do
    create_transformed_row(1, 111)

    job = TransformDataMigrationSuccessJob.new()
    @batch.update!(metadata: @batch.metadata.merge("continue_to_next_stage" => false))
    job.batch_id = @batch.id
    job.perform_now

    assert_no_enqueued_jobs only: LoadDataMigrationJob
  end

  test "does not enqueues load job when continuing and prerequisite fails (transform rows does not exist)" do
    job = TransformDataMigrationSuccessJob.new()
    job.batch_id = @batch.id
    job.perform_now

    assert_no_enqueued_jobs only: LoadDataMigrationJob
  end

  private

  def create_transformed_row(row_number, health_identifier)
    now = Time.current
    raw = RawPatientDatum.create!(
      data_migration_id: @data_migration.id,
      row_number: row_number,
      source_hash: "raw_hash_#{row_number}"
    )

    TransformedPatientDatum.create!(
      data_migration_id: @data_migration.id,
      raw_patient_data_id: raw.id,
      row_number: row_number,
      transformation_status: "valid",
      patient_health_identifier_number: health_identifier,
      patient_health_identifier_number_province: "BC",
      first_name: "Matthew",
      last_name: "Brown",
      address_line_1: "2237 Sun Valley Dr.",
      city: "Nanaimo",
      province: "British Columbia",
      postal_code: "V9T6E8",
      dob: "1988-04-05",
      sex: "Male",
      source_hash: "source_hash_#{row_number}",
      address_target_hash: "address_hash_#{row_number}",
      created_at: now,
      updated_at: now
    )
  end
end
