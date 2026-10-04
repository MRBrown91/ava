class DataMigration::CsvUpload < ApplicationRecord
  belongs_to :data_migration
  has_one_attached :file

  def source_file
    file.blob
  end
end
