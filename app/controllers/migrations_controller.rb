require "csv"

class MigrationsController < ApplicationController
  def index
    sort_column = params[:s].presence_in(%w[id source_type status started_at completed_at rows_processed]) || "started_at"
    sort_direction = params[:d].presence_in(%w[asc desc]) || "asc"
    sorting_order = {
      sort_column => sort_direction,
      "id" => sort_direction
    }

    @sort_column = sort_column
    @sort_direction = sort_direction
    @pagy, @data_migrations = pagy(:offset, DataMigration.all.order(sorting_order), limit: 20)
  end

  def show
    @data_migration = DataMigration.find(params[:id])
    @migration_errors = @data_migration.data_migration_errors.order(:created_at)
  end

  def new
    @data_migrations = DataMigration.new
  end

  def create
    start = Timing.start_ms

    data_migration = DataMigration.create!(
      source_type: "csv_upload",
      status: "pending",
      started_at: Time.current
    )
    csv_upload = data_migration.create_csv_upload!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id
    )

    errors = ::Validators::CsvUpload.new(params[:csv_file]).call
    if errors.present?
      handle_failed_upload(data_migration, "Validation", errors, start)
      return
    end

    begin
      csv_upload.file.attach(params[:csv_file]).save!

      DataMigrationJob.perform_later(data_migration.id)

      data_migration.update!(
        preprocessing_time_ms: Timing.elapsed_ms(start)
      )

      flash[:success] = "Migration started"
      redirect_to migration_path(data_migration), status: :see_other

    rescue StandardError => e
      csv_upload.file.purge if csv_upload.file.attached?

      handle_failed_upload(
        data_migration,
        e.class,
        [ "Upload failed: #{e.message}" ],
        start
      )

      Rails.error.report(e)
    end
  end

  private

  def handle_failed_upload(data_migration, error_class, errors, start)
    data_migration.update!(
      preprocessing_time_ms: Timing.elapsed_ms(start),
      status: "failed",
      completed_at: Time.current
    )

    errors.each do |message|
      data_migration.data_migration_errors.create!(
        severity: "error",
        stage: "preprocessing",
        error_class: error_class,
        message: message
      )
    end

    flash[:alert] = errors
    redirect_to new_migration_path, status: :see_other
  end
end
