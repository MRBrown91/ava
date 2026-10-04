module Migrations
  class LoadService
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
      rows_processed = 0
      rows_inserted = 0
      rows_updated = 0
      rows_skipped = 0
      rows_failed = 0

      timestamp = Time.current

      transformed_patients =
        TransformedPatientDatum
          .where(data_migration_id: data_migration.id)
          .where(transformation_status: "valid")
          .order(:row_number)

      transformed_patients.find_each do |transformed_patient|
        rows_processed += 1

        begin
          result = load_patient(
            data_migration,
            transformed_patient,
            timestamp
          )

          case result
          when :inserted
            rows_inserted += 1
          when :updated
            rows_updated += 1
          when :skipped
            rows_skipped += 1
          end
        rescue StandardError => e
          rows_failed += 1

          Rails.logger.error("Load failed for transformed patient #{transformed_patient.id}: #{e.class}: #{e.message}")

          data_migration.data_migration_errors.create!(
            severity: "error",
            stage: "load",
            error_class: e.class.name,
            message: e.message
          )
        end
      end

      {
        rows_processed: rows_processed,
        rows_inserted: rows_inserted,
        rows_updated: rows_updated,
        rows_skipped: rows_skipped,
        rows_failed: rows_failed
      }
    end

    def self.load_patient(data_migration, transformed_patient, timestamp)
      return :skipped if Patient.exists?(source_hash: transformed_patient.source_hash)

      current_patient = Patient.find_by(
        patient_health_identifier_number: transformed_patient.patient_health_identifier_number,
        patient_health_identifier_number_province: transformed_patient.patient_health_identifier_number_province,
        is_current: true
      )

      Patient.transaction do
        address = find_or_create_address(transformed_patient)

        if current_patient
          current_patient.update!(
            valid_to: timestamp,
            is_current: false
          )

          create_patient(
            data_migration,
            transformed_patient,
            address,
            timestamp
          )

          :updated
        else
          create_patient(
            data_migration,
            transformed_patient,
            address,
            timestamp
          )

          :inserted
        end
      end
    end

    def self.create_patient(
      data_migration,
      transformed_patient,
      address,
      timestamp
    )
      Patient.create!(
        data_migration: data_migration,
        address: address,
        patient_health_identifier_number: transformed_patient.patient_health_identifier_number,
        patient_health_identifier_number_province: transformed_patient.patient_health_identifier_number_province,
        first_name: transformed_patient.first_name,
        last_name: transformed_patient.last_name,
        middle_name: transformed_patient.middle_name,
        phone: transformed_patient.phone,
        email: transformed_patient.email,
        dob: transformed_patient.dob,
        sex: transformed_patient.sex,
        source_hash: transformed_patient.source_hash,
        valid_from: timestamp,
        valid_to: nil,
        is_current: true
      )
    end

    def self.find_or_create_address(transformed_patient)
      transformed_address = TransformedAddressDatum.find_by!(
        data_migration_id: transformed_patient.data_migration_id,
        raw_patient_data_id: transformed_patient.raw_patient_data_id
      )
      address_hash = hash_address(transformed_address)

      Address.find_or_create_by!(source_hash: address_hash) do |address|
        address.address_line_1 = transformed_address.address_line_1
        address.address_line_2 = transformed_address.address_line_2
        address.city = transformed_address.city
        address.province = transformed_address.province
        address.postal_code = transformed_address.postal_code
      end
    end

    def self.hash_address(transformed_address)
      Digest::SHA256.hexdigest(
        [
          transformed_address.address_line_1,
          transformed_address.address_line_2,
          transformed_address.city,
          transformed_address.province,
          transformed_address.postal_code
        ].map(&:to_s).join("|")
      )
    end
  end
end
