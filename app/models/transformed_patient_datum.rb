class TransformedPatientDatum < ApplicationRecord
  belongs_to :data_migration
  belongs_to :raw_patient_data, class_name: "RawPatientDatum"
end
