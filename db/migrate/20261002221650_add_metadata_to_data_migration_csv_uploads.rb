class AddMetadataToDataMigrationCsvUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :data_migration_csv_uploads, :ip_address, :string
    add_column :data_migration_csv_uploads, :user_agent, :string
    add_column :data_migration_csv_uploads, :request_id, :string
  end
end
