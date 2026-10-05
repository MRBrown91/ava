require "test_helper"

class TransformDataMigrationFailureJobTest < ActiveJob::TestCase
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
      failed_jobs: 2,
      finished_at: Time.current,
      failed_at: Time.current
    )
  end

  test "metadata recorded on failure" do
    job = TransformDataMigrationFailureJob.new
    job.batch_id = @batch.id
    job.perform_now

    assert_equal "failed", @data_migration.reload.status
    assert_not_nil @data_migration.completed_at
    assert_not_nil @data_migration.transform_completed_at
    assert_operator @data_migration.transform_time_ms, :>, 0
  end

  test "error recorded on failure" do
    job = TransformDataMigrationFailureJob.new
    job.batch_id = @batch.id
    job.perform_now

    recorded = DataMigration::Error.find_by(
      data_migration_id: @data_migration.id,
      stage: "transformation"
    )

    assert_not_nil recorded
    assert_equal "error", recorded.severity
    assert_equal "SolidQueue::BatchFailure", recorded.error_class
    assert_equal "Transformation batch failed: 2/4 jobs failed", recorded.message
  end
end
