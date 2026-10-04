module Migrations
  class LoadService
    INSERT_ADDRESSES_SQL = <<~SQL.freeze
      INSERT INTO addresses (
        address_line_1,
        address_line_2,
        city,
        province,
        postal_code,
        source_hash,
        created_at,
        updated_at
      )
      SELECT t.address_line_1, t.address_line_2, t.city, t.province, t.postal_code, t.address_target_hash, :now, :now
      FROM transformed_patient_data t
      WHERE t.data_migration_id = :migration_id
        AND t.transformation_status = 'valid'
        AND NOT EXISTS (SELECT 1 FROM patients p WHERE p.source_hash = t.source_hash)
        AND t.address_target_hash IS NOT NULL
      ON CONFLICT (source_hash) DO NOTHING
    SQL

    UPDATE_PATIENTS_SQL = <<~SQL.freeze
      UPDATE patients SET
        valid_to = :now,
        is_current = false,
        updated_at = :now
      WHERE is_current = true AND (patient_health_identifier_number, patient_health_identifier_number_province) IN#{' '}
        (
          SELECT patient_health_identifier_number::text, patient_health_identifier_number_province
          FROM transformed_patient_data t
          WHERE t.data_migration_id = :migration_id
            AND t.transformation_status = 'valid'
            AND NOT EXISTS (SELECT 1 FROM patients p WHERE p.source_hash = t.source_hash)
        )
    SQL

    INSERT_PATIENTS_SQL = <<~SQL.freeze
      INSERT INTO patients (
        data_migration_id,
        address_id,
        patient_health_identifier_number,
        patient_health_identifier_number_province,
        first_name,
        last_name,
        middle_name,
        phone,
        email,
        dob,
        sex,
        source_hash,
        valid_from,
        valid_to,
        is_current,
        created_at,
        updated_at
      )
      SELECT
        :migration_id,
        a.id,
        t.patient_health_identifier_number::text,
        t.patient_health_identifier_number_province,
        t.first_name,
        t.last_name,
        t.middle_name,
        t.phone,
        t.email,
        t.dob,
        t.sex,
        t.source_hash,
        :now,
        NULL,
        true,
        :now,
        :now
      FROM transformed_patient_data t
      JOIN addresses a ON a.source_hash = t.address_target_hash
      WHERE t.data_migration_id = :migration_id
        AND t.transformation_status = 'valid'
        AND NOT EXISTS (SELECT 1 FROM patients p WHERE p.source_hash = t.source_hash)
    SQL

    def self.check_prerequisites(data_migration_id)
      # PreRequisite 1: Data Migration Exists
      data_migration = DataMigration.find_by(id: data_migration_id)
      return false unless data_migration

      # Prerequisite 2: Transformed Data Exists
      transformed_data_count = TransformedPatientDatum.where(data_migration_id: data_migration_id).where(transformation_status: "valid").count
      return false unless transformed_data_count > 0

      true
    end

    def self.load(data_migration)
      timestamp = Time.current

      transformed_patients = TransformedPatientDatum.where(data_migration_id: data_migration.id)

      rows_processed = transformed_patients.count
      rows_valid = transformed_patients.where(transformation_status: "valid").count
      rows_invalid = rows_processed - rows_valid

      invalid_rows = transformed_patients.where.not(transformation_status: "valid").pluck(:row_number, :transformation_error)
      if !invalid_rows.empty?
        DataMigration::Error.insert_all(
          invalid_rows.map do |row_number, error|
            {
              data_migration_id: data_migration.id,
              severity: "warning",
              stage: "load",
              row_id: row_number,
              error_class: "InvalidRow",
              message: "Row #{row_number}: #{error || 'Unknown error'}",
              created_at: timestamp,
              updated_at: timestamp
            }
          end
        )
      end

      update_patients_count = 0
      insert_patients_count = 0
      ActiveRecord::Base.transaction do
        insert_addresses = ActiveRecord::Base.sanitize_sql_array([
          INSERT_ADDRESSES_SQL,
          { migration_id: data_migration.id, now: timestamp }
        ])
        ActiveRecord::Base.connection.exec_update(insert_addresses)

        updated_patients = ActiveRecord::Base.sanitize_sql_array([
          UPDATE_PATIENTS_SQL,
          { migration_id: data_migration.id, now: timestamp }
        ])
        update_patients_count = ActiveRecord::Base.connection.exec_update(updated_patients)

        insert_patients = ActiveRecord::Base.sanitize_sql_array([
          INSERT_PATIENTS_SQL,
          { migration_id: data_migration.id, now: timestamp }
        ])
        insert_patients_count = ActiveRecord::Base.connection.exec_update(insert_patients)
      end

      {
        rows_processed: rows_processed,
        rows_inserted: insert_patients_count - update_patients_count,
        rows_updated: update_patients_count,
        rows_skipped: rows_valid - insert_patients_count,
        rows_failed: rows_invalid
      }
    end
  end
end
