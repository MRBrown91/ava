class TransformDataMigrationJob < ApplicationJob
  queue_as :transform

  CHUNK_SIZE = 500

  def perform(data_migration_id, continue_to_next_stage = true)
    start = Timing.start_ms
    Rails.logger.info("Transformation: Starting phase for migration #{data_migration_id}")

    data_migration = DataMigration.find(data_migration_id)
    data_migration.update!(
      status: "transforming",
      transform_started_at: Time.current
    )

    begin

      chunks = []
      from_row = RawPatientDatum.where(data_migration: data_migration.id).minimum(:row_number)
      max_row = RawPatientDatum.where(data_migration: data_migration.id).maximum(:row_number)
      if from_row.nil?
        raise RuntimeError.new("Transformation running on empty raw set.")
      end
      while from_row <= max_row do
        to_row = [ from_row + CHUNK_SIZE - 1, max_row ].min
        chunks << [ data_migration.id, from_row, to_row ]
        from_row = from_row + CHUNK_SIZE
      end

      SolidQueue::Batch.enqueue(
        on_success: TransformDataMigrationSuccessJob,
        on_failure: TransformDataMigrationFailureJob,
        data_migration_id: data_migration.id,
        continue_to_next_stage: continue_to_next_stage
      ) do |batch|
        chunks.each do |chunk|
          Rails.logger.info("Transformation ##{data_migration.id}: Scheduling job for rows #{chunk[1]}-#{chunk[2]}")
          TransformDataMigrationChunkJob.perform_later(*chunk)
        end
      end

    rescue StandardError => e
      Rails.logger.error("#{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      data_migration.update!(
        status: "failed",
        transform_completed_at: Time.current,
        completed_at: Time.current,
        transform_time_ms: Timing.elapsed_ms(start)
      )

      data_migration.data_migration_errors.create!(
        severity: "error",
        stage: "transformation",
        error_class: e.class.name,
        message: e.message
      )
      raise
    end
  end
end
