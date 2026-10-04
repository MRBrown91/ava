class TransformDataMigrationChunkJob < ApplicationJob
  queue_as :transform

  def perform(data_migration_id, start_row, end_row)
    start = Timing.start_ms
    Rails.logger.info("Transformation ##{data_migration_id}: Starting job for rows #{start_row}-#{end_row}")

    data_migration = DataMigration.find(data_migration_id)

    timestamp = Time.current
    transformed_addresses = []
    transformed_patients = []

    # (IN PROD): Consider raw PostgreSQL cursors for performance
    RawPatientDatum
    .where(data_migration_id: data_migration.id)
    .where(row_number: start_row..end_row)
    .pluck(
      :id,
      :row_number,
      :health_identifier,
      :health_identifier_province,
      :first_name,
      :last_name,
      :middle_name,
      :phone,
      :email,
      :address_1,
      :address_2,
      :address_province,
      :address_city,
      :address_postal_code,
      :date_of_birth,
      :sex,
      :source_hash
    )
    .each do |raw_row|
      raw_object = {
        id: raw_row[0],
        row_number: raw_row[1],
        health_identifier: raw_row[2],
        health_identifier_province: raw_row[3],
        first_name: raw_row[4],
        last_name: raw_row[5],
        middle_name: raw_row[6],
        phone: raw_row[7],
        email: raw_row[8],
        address_1: raw_row[9],
        address_2: raw_row[10],
        address_province: raw_row[11],
        address_city: raw_row[12],
        address_postal_code: raw_row[13],
        date_of_birth: raw_row[14],
        sex: raw_row[15],
        source_hash: raw_row[16]
      }
      transformed_addresses << Migrations::TransformService.transform_address(data_migration.id, raw_object, timestamp)
      transformed_patients << Migrations::TransformService.transform_patient(data_migration.id, raw_object, timestamp)
    end

    ActiveRecord::Base.transaction do
      TransformedAddressDatum.insert_all(
        transformed_addresses
      )

      TransformedPatientDatum.insert_all(
        transformed_patients
      )
    end

    Rails.logger.info("Transformation ##{data_migration_id}: Completed job for rows #{start_row}-#{end_row} in #{Timing.elapsed_ms(start)} ms")
  rescue StandardError => e
    Rails.logger.info("Transformation ##{data_migration_id}: Failed job for rows #{start_row}-#{end_row} in #{Timing.elapsed_ms(start)} ms with #{e.class}: #{e.message}")
    raise
  end
end
