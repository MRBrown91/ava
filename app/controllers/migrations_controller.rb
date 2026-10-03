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
  end

  def new
    @data_migrations = DataMigration.new
  end

  def create
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

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
      handle_failed_upload(data_migration, errors, start)
      return
    end

    begin
      csv_upload.file.attach(params[:csv_file]).save!

      # start worker

      data_migration.update!(
        preprocessing_time_ms: elapsed_ms(start)
      )

      flash[:success] = "Migration started"
      redirect_to migration_path(data_migration), status: :see_other

    rescue StandardError => e
      csv_upload.file.purge if csv_upload.file.attached?

      handle_failed_upload(
        data_migration,
        [ "Upload failed: #{e.message}" ],
        start
      )

      Rails.error.report(e)
    end
  end

  private

  def elapsed_ms(start)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).to_i
  end

  def handle_failed_upload(data_migration, errors, start)
    data_migration.update!(
      preprocessing_time_ms: elapsed_ms(start),
      status: "failed",
      completed_at: Time.current
    )

    errors.each do |message|
      data_migration.data_migration_errors.create!(
        severity: "error",
        stage: "preprocessing",
        message: message
      )
    end

    flash[:alert] = errors
    redirect_to new_migration_path, status: :see_other
  end
end
