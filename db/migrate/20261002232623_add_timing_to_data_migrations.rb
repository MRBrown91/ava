class AddTimingToDataMigrations < ActiveRecord::Migration[8.1]
  def change
    add_column :data_migrations, :preprocessing_time_ms, :integer

    add_column :data_migrations, :extract_started_at, :datetime
    add_column :data_migrations, :extract_completed_at, :datetime
    add_column :data_migrations, :extract_time_ms, :integer
    add_column :data_migrations, :rows_extracted, :integer
    add_column :data_migrations, :extracted_size_bytes, :integer
    add_column :data_migrations, :transform_started_at, :datetime
    add_column :data_migrations, :transform_completed_at, :datetime
    add_column :data_migrations, :transform_time_ms, :integer
    add_column :data_migrations, :rows_transformed, :integer
    add_column :data_migrations, :rows_skipped_at_transform, :integer
    add_column :data_migrations, :load_started_at, :datetime
    add_column :data_migrations, :load_completed_at, :datetime
    add_column :data_migrations, :load_time_ms, :integer
    add_column :data_migrations, :rows_loaded, :integer
    add_column :data_migrations, :rows_skipped_at_load, :integer
  end
end
