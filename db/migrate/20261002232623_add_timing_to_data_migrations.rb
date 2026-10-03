class AddTimingToDataMigrations < ActiveRecord::Migration[8.1]
  def change
    add_column :data_migrations, :preprocessing_time_ms, :integer
    add_column :data_migrations, :extract_time_ms, :integer
    add_column :data_migrations, :transform_time_ms, :integer
    add_column :data_migrations, :load_time_ms, :integer
  end
end
