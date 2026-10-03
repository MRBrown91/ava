class DataMigration::CsvUpload < ApplicationRecord
  belongs_to :data_migration, optional: true
  has_one_attached :file
end
