class TransformDataMigrationFailureJob < ApplicationJob
  queue_as :transform

  def perform
    data_migration_id = batch.metadata["data_migration_id"]
    data_migration = DataMigration.find(data_migration_id)

    Rails.logger.error("Transformation ##{data_migration_id} failed: #{batch.failed_jobs}/#{batch.total_jobs} jobs failed")

    data_migration.update!(
      status: "failed",
      transform_completed_at: Time.current,
      completed_at: Time.current,
      transform_time_ms: (Time.current - data_migration.transform_started_at).in_milliseconds.to_i
    )

    data_migration.data_migration_errors.create!(
      severity: "error",
      stage: "transformation",
      error_class: "SolidQueue::BatchFailure",
      message: "Transformation batch failed: #{batch.failed_jobs}/#{batch.total_jobs} jobs failed"
    )
  end
end
