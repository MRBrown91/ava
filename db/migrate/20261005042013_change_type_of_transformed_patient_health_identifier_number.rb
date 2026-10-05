class ChangeTypeOfTransformedPatientHealthIdentifierNumber < ActiveRecord::Migration[8.1]
  def change
    change_column :transformed_patient_data, :patient_health_identifier_number, :string
  end
end
