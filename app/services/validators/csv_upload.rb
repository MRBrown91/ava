module Validators
  class CsvUpload
    REQUIRED_HEADERS = [
      "health identifier",
      "health identifier province"
    ].freeze

    OPTIONAL_HEADERS = [
      "first name",
      "last name",
      "middle name",
      "phone",
      "email",
      "address 1",
      "address 2",
      "address province",
      "address city",
      "address postal code",
      "date of birth",
      "sex"
    ].freeze

    ALLOWED_MIME_TYPES = [
      "text/csv",
      "text/plain",
      "application/csv",
      "application/vnd.ms-excel",
      "application/octet-stream"
    ].freeze

    MAX_SIZE = 1.gigabytes

    def initialize(file)
      @file = file
    end

    def call
      errors = []

      # Check 1: Existance
      if @file.blank?
        return [ "No file was uploaded." ]
      end

      # Check 2: Size
      errors << "File too large (Max. 1 GB)." if @file.size > MAX_SIZE

      # Check 3: Extension
      errors << "Invalid file extension. Please upload a CSV file." if File.extname(@file.original_filename).downcase.strip != ".csv"

      # Check 4: Mime
      errors << "Invalid file type. Please upload a CSV file." if !ALLOWED_MIME_TYPES.include?(@file.content_type)

      # Check 5: Structure
      if errors.empty?
        begin
          headers = CSV.open(@file.path, headers: true, encoding: "bom|utf-8") do |csv|
            csv.first&.headers
          end
          if headers.blank?
            errors << "CSV contains no headers."
          else
            missing_headers = REQUIRED_HEADERS - headers
            errors << "Required Headers are missing: #{missing_headers}." if missing_headers.present?
            invalid_headers = headers - (REQUIRED_HEADERS + OPTIONAL_HEADERS)
            errors << "Invalid Headers are included: #{invalid_headers}" if invalid_headers.present?
          end

        rescue CSV::MalformedCSVError => e
          errors << "CSV is malformed: #{e.message}"
        rescue ArgumentError => e
          errors << "CSV encoding is invalid: #{e.message}"
        end
      end

      # Check 6 (IN PROD): Guard against CSV injection

      errors
    end
  end
end
