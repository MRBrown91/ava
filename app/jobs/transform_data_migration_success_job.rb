class TransformDataMigrationSuccessJob < ApplicationJob
  queue_as :transform

  def perform
    data_migration_id = batch.metadata["data_migration_id"]
    continue_to_next_stage = batch.metadata["continue_to_next_stage"]

    data_migration = DataMigration.find(data_migration_id)

    Migrations::DeduplicateService.deduplicate(data_migration.id)

    data_migration.update!(
      status: "transformation_complete",
      transform_completed_at: Time.current,
      transform_time_ms: (Time.current - data_migration.transform_started_at).in_milliseconds.to_i
    )

    if continue_to_next_stage && Migrations::LoadService.check_prerequisites(data_migration_id)
      LoadDataMigrationJob.perform_later(data_migration.id)
    end
  end
end
