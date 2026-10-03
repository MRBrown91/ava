class CreateDataMigrationCsvUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :data_migration_csv_uploads do |t|
      t.references :data_migration, null: false, foreign_key: true
      t.string :filename

      t.timestamps
    end
  end
end
