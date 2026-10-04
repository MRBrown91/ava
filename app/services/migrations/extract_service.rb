module Migrations
  class ExtractService
    COPY_SQL = <<~SQL.freeze
      COPY raw_patient_data (
        data_migration_id,
        row_number,
        health_identifier,
        health_identifier_province,
        first_name,
        last_name,
        middle_name,
        phone,
        email,
        address_1,
        address_2,
        address_province,
        address_city,
        address_postal_code,
        date_of_birth,
        sex,
        source_hash,
        created_at
      )
      FROM STDIN WITH (FORMAT CSV)
    SQL

    def self.check_prerequisites(data_migration_id)
      # PreRequisite 1: Data Migration Exists
      data_migration = DataMigration.find_by(id: data_migration_id)
      return false unless data_migration

      # Prerequisite 2: Data Migration Has a Source
      source_file = data_migration.source_file
      return false unless source_file

      # Prerequisite 3: Source File Can Open
      begin
        source_file.open do |_file|
        end
      rescue StandardError
        return false
      end

      true
    end

    def self.extract(data_migration)
      row_number = 0

      data_migration.source_file.open do |csv_file|
        Rails.logger.info("Extraction ##{data_migration.id}: COPY Transaction started")
        ActiveRecord::Base.transaction do
          RawPatientDatum.where(data_migration_id: data_migration.id).delete_all

          created_at = Time.current
          raw_connection = ActiveRecord::Base.connection.raw_connection
          raw_connection.copy_data(COPY_SQL) do
            CSV.foreach(csv_file.path, headers: true) do |row|
              row_number += 1

              source_hash = Digest::SHA256.hexdigest(
                [
                  row["health identifier"],
                  row["health identifier province"],
                  row["first name"],
                  row["last name"],
                  row["middle name"],
                  row["phone"],
                  row["email"],
                  row["address 1"],
                  row["address 2"],
                  row["address province"],
                  row["address city"],
                  row["address postal code"],
                  row["date of birth"],
                  row["sex"]
                ].map(&:to_s).join("|")
              )

              copy_row = [
                data_migration.id,
                row_number,
                row["health identifier"],
                row["health identifier province"],
                row["first name"],
                row["last name"],
                row["middle name"],
                row["phone"],
                row["email"],
                row["address 1"],
                row["address 2"],
                row["address province"],
                row["address city"],
                row["address postal code"],
                row["date of birth"],
                row["sex"],
                source_hash,
                created_at
              ]

              raw_connection.put_copy_data(CSV.generate_line(copy_row))
            end
          end
        end
        Rails.logger.info("Extraction ##{data_migration.id}: COPY transaction completed")
      end

      {
        rows_extracted: row_number,
        size_extracted: data_migration.source_file.byte_size
      }
    end
  end
end
