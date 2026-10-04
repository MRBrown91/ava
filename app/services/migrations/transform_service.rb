module Migrations
  class TransformService
    PROVINCE_CODES = %w[
      AB BC MB NB NL NS ON PE QC SK NT NU YT
    ].freeze

    def self.check_prerequisites(data_migration_id)
      # PreRequisite 1: Data Migration Exists
      data_migration = DataMigration.find_by(id: data_migration_id)
      return false unless data_migration

      # Prerequisite 2: Raw Data Exists
      raw_data_count = RawPatientDatum.where(data_migration_id: data_migration_id).count
      return false unless raw_data_count > 0

      true
    end

    def self.transform_patient(data_migration_id, raw_object, timestamp)
      h_id = normalize_health_identifier(raw_object[:health_identifier])
      h_province = normalize_province(raw_object[:health_identifier_province])
      transformation_error = validate_patient(h_id, h_province)

      address_line_1 = normalize_address(raw_object[:address_1])
      address_line_2 = normalize_address(raw_object[:address_2])
      address_city = normalize_string(raw_object[:address_city])
      address_province = normalize_province(raw_object[:address_province])
      address_postal_code = normalize_postal_code(raw_object[:address_postal_code])
      address_hash = hash_address(address_line_1, address_line_2, address_city, address_province, address_postal_code)

      {
        data_migration_id: data_migration_id,
        raw_patient_data_id: raw_object[:id],
        row_number: raw_object[:row_number],
        transformation_status: transformation_error ? "invalid" : "valid",
        transformation_error: transformation_error,
        patient_health_identifier_number: h_id,
        patient_health_identifier_number_province: h_province,
        first_name: normalize_name(raw_object[:first_name]),
        last_name: normalize_name(raw_object[:last_name]),
        middle_name: normalize_name(raw_object[:middle_name]),
        phone: normalize_phone(raw_object[:phone]),
        email: normalize_email(raw_object[:email]),
        dob: normalize_date(raw_object[:date_of_birth]),
        sex: normalize_sex(raw_object[:sex]),
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        city: address_city,
        province: address_province,
        postal_code: address_postal_code,
        source_hash: raw_object[:source_hash],
        address_target_hash: address_hash,
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    def self.validate_patient(h_id, h_province)
      errors = []

      if h_id.blank?
        errors << "Health identifier is required"
      end

      if h_province.blank?
        errors << "Health identifier province is required"
      elsif !PROVINCE_CODES.include?(h_province)
        errors << "Health identifier province is invalid"
      end

      errors.empty? ? nil : errors.join("; ")
    end

    def self.normalize_string(address)
      return address if address.blank?

      address = address.upcase
      address = address.split.join(" ")
      address = address.gsub(/[.,;#]/, "")

      address
    end

    def self.normalize_address(address)
      return address if address.blank?
      address = normalize_string(address)
      replacements = {
        "STREET"    => "ST",
        "AVENUE"    => "AVE",
        "BOULEVARD" => "BLVD",
        "DRIVE"     => "DR",
        "COURT"     => "CRT",
        "WEST"      => "W",
        "EAST"      => "E",
        "NORTH"     => "N",
        "SOUTH"     => "S",
        "APARTMENT" => "APT",
        "SUITE"     => "STE"
      }
      replacements.each do |find, replacement|
        address.gsub!(/\b#{find}\b/, replacement)
      end

      address
    end

    def self.normalize_province(province)
      return province if province.blank?
      province = normalize_string(province)

      {
        "ALBERTA" => "AB",
        "BRITISH COLUMBIA" => "BC",
        "MANITOBA" => "MB",
        "NEW BRUNSWICK" => "NB",
        "NEWFOUNDLAND AND LABRADOR" => "NL",
        "NOVA SCOTIA" => "NS",
        "ONTARIO" => "ON",
        "PRINCE EDWARD ISLAND" => "PE",
        "QUEBEC" => "QC",
        "SASKATCHEWAN" => "SK",
        "NORTHWEST TERRITORIES" => "NT",
        "NUNAVUT" => "NU",
        "YUKON" => "YT"
      }.fetch(province, province)
    end

    def self.normalize_postal_code(postal_code)
      return postal_code if postal_code.blank?

      postal_code = postal_code.upcase
      postal_code = postal_code.split.join("")
      postal_code = "#{postal_code[0, 3]} #{postal_code[3, 3]}" if postal_code.length == 6

      postal_code
    end

    def self.normalize_health_identifier(health_identifier)
      # Need More Infroamtion Here.  Preserved as string to keep 003 distinct from 3.  This may be unnecessary in which case this can be simplified
      return nil if health_identifier.blank?

      health_identifier = health_identifier.to_s.strip

      return "0" if health_identifier == "0"

      return nil unless health_identifier.match?(/\A\d+\z/)

      health_identifier
    end

    def self.normalize_phone(phone)
      return nil if phone.blank?

      phone = phone.to_s.gsub(/\D/, "")
      return nil if phone.blank?

      return nil if ![ 7, 10, 11 ].include?(phone.length)
      phone = phone[1..] if phone.length == 11 && phone.start_with?("1")

      phone
    end

    def self.normalize_email(email)
      return nil if email.blank? || !email.include?("@")

      email.to_s.strip.downcase
    end

    def self.normalize_name(name)
      return name if name.blank?

      name.to_s.split.join(" ")
    end

    def self.normalize_date(date)
      return nil if date.blank?

      date = if date.is_a?(Date) || date.is_a?(Time) || date.is_a?(DateTime)
        date.to_date
      else
        Date.parse(date.to_s.strip)
      end

      date
    rescue ArgumentError
      nil
    end

    def self.normalize_sex(sex)
      return "UKN" if sex.blank?

      sex = normalize_string(sex)
      {
        "M" => "M",
        "MALE" => "M",
        "MAN" => "M",

        "F" => "F",
        "FEMALE" => "F",
        "WOMAN" => "F",

        "NB" => "NB",
        "N.B." => "NB",
        "NON-BINARY" => "NB",
        "NONBINARY" => "NB",
        "NON BINARY" => "NB"
      }.fetch(sex, "UKN")
    end

    def self.hash_address(address_line_1, address_line_2, address_city, address_province, address_postal_code)
      Digest::SHA256.hexdigest(
        [
          address_line_1,
          address_line_2,
          address_city,
          address_province,
          address_postal_code
        ].map(&:to_s).join("|")
      )
    end
  end
end
