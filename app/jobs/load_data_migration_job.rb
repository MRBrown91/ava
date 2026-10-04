class LoadDataMigrationJob < ApplicationJob
  queue_as :load

  def perform(data_migration_id)
    start = Timing.start_ms
    Rails.logger.info("Load: Starting phase for migration #{data_migration_id}")

    data_migration = DataMigration.find(data_migration_id)
    data_migration.update!(
      status: "loading",
      load_started_at: Time.current
    )

    begin
      result = Migrations::LoadService.load(data_migration)

      data_migration.update!(
        status: "complete",
        completed_at: Time.current,
        load_completed_at: Time.current,
        load_time_ms: Timing.elapsed_ms(start),
        rows_processed: result[:rows_processed],
        rows_inserted: result[:rows_inserted],
        rows_updated: result[:rows_updated],
        rows_skipped: result[:rows_skipped],
        rows_failed: result[:rows_failed]
      )

    rescue StandardError => e
      Rails.logger.error("#{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      data_migration.update!(
        status: "failed",
        load_completed_at: Time.current,
        completed_at: Time.current,
        load_time_ms: Timing.elapsed_ms(start)
      )

      data_migration.data_migration_errors.create!(
        severity: "error",
        stage: "load",
        error_class: e.class.name,
        message: e.message
      )
      raise
    end
  end
end
