module Migrations
  class DeduplicateService
    def self.deduplicate(data_migration_id)
      duplicates = TransformedPatientDatum
        .where(data_migration_id: data_migration_id)
        .where(transformation_status: "valid")
        .where.not(patient_health_identifier_number: nil)
        .where.not(patient_health_identifier_number_province: nil)
        .group(
          :patient_health_identifier_number,
          :patient_health_identifier_number_province
        )
        .having("COUNT(*) > 1")
        .pluck(
          :patient_health_identifier_number,
          :patient_health_identifier_number_province
        )

      duplicates.each do | health_identifier, province |
        rows = TransformedPatientDatum
          .where(
            data_migration_id: data_migration_id,
            patient_health_identifier_number: health_identifier,
            patient_health_identifier_number_province: province,
            transformation_status: "valid"
          )
          .order(row_number: :desc)
        rows.offset(1).update_all(
          transformation_status: "invalid",
          transformation_error: "Duplicate health identifier and province",
          updated_at: Time.current
        )
      end
    end
  end
end
