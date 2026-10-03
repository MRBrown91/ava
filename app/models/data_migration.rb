class DataMigration < ApplicationRecord
  has_one :csv_upload,
    class_name: "DataMigration::CsvUpload",
    dependent: :destroy

  has_many :data_migration_errors,
    class_name: "DataMigration::Error",
    dependent: :destroy
end
