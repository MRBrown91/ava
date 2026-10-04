class DataMigrationJob < ApplicationJob
  queue_as :default

  def perform(data_migration_id)
    data_migration = DataMigration.find(data_migration_id)
    data_migration.update!(
      status: "processing"
    )

    if !Migrations::ExtractService.check_prerequisites(data_migration_id)
      data_migration.update!(
        status: "failed",
        completed_at: Time.current
      )
      data_migration.data_migration_errors.create!(
          severity: "error",
          stage: "processing",
          error_class: "PreRequisite",
          message: "Extraction prerequisites not met."
        )
      return
    end

    ExtractDataMigrationJob.perform_later(data_migration.id, true)
  end
end
