class CreateDataMigrations < ActiveRecord::Migration[8.1]
  def change
    create_table :data_migrations do |t|
      t.string :source_type
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :rows_processed
      t.integer :rows_inserted
      t.integer :rows_updated
      t.integer :rows_skipped
      t.integer :rows_failed

      t.timestamps
    end
  end
end
