class ExtractDataMigrationJob < ApplicationJob
  queue_as :extract

  def perform(data_migration_id, continue_to_next_stage = true)
    start = Timing.start_ms
    Rails.logger.info("Extraction: Starting phase for migration #{data_migration_id}")

    data_migration = DataMigration.find(data_migration_id)
    data_migration.update!(
      status: "extracting",
      extract_started_at: Time.current
    )

    # (IN PROD) Consider chunking/seperating into seperate jobs/setting up checkpoints
    begin
      result = Migrations::ExtractService.extract(data_migration)

      data_migration.update!(
        status: "extraction_complete",
        extract_completed_at: Time.current,
        extract_time_ms: Timing.elapsed_ms(start),
        rows_extracted: result[:rows_extracted],
        extracted_size_bytes: result[:size_extracted],
      )

      if continue_to_next_stage && Migrations::TransformService.check_prerequisites(data_migration_id)
        TransformDataMigrationJob.perform_later(data_migration.id)
      end

    rescue StandardError => e
      Rails.logger.error("#{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      data_migration.update!(
        status: "failed",
        extract_completed_at: Time.current,
        completed_at: Time.current,
        extract_time_ms: Timing.elapsed_ms(start)
      )

      data_migration.data_migration_errors.create!(
        severity: "error",
        stage: "extraction",
        error_class: e.class.name,
        message: e.message
      )
      raise
    end
  end
end
