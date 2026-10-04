class DataMigration < ApplicationRecord
  has_one :csv_upload,
    class_name: "DataMigration::CsvUpload",
    dependent: :destroy

  has_many :data_migration_errors,
    class_name: "DataMigration::Error",
    dependent: :destroy


  def source
    case source_type
    when "csv_upload"
        csv_upload
    else
      raise ArgumentError, "Unsupported source type: #{source_type}"
    end
  end

  def source_file
    case source_type
    when "csv_upload"
        csv_upload.source_file
    else
      raise ArgumentError, "Unsupported source type: #{source_type}"
    end
  end
end
