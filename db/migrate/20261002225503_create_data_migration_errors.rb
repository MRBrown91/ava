class CreateDataMigrationErrors < ActiveRecord::Migration[8.1]
  def change
    create_table :data_migration_errors do |t|
      t.references :data_migration, null: false, foreign_key: true
      t.string :severity
      t.string :stage
      t.string :error_class
      t.text :message
      t.integer :row_id

      t.timestamps
    end
  end
end
