class CreateTransformedPatientData < ActiveRecord::Migration[8.1]
  def change
    create_table :transformed_patient_data do |t|
      t.references :data_migration, null: false
      t.references :raw_patient_data, null: false, index: false
      t.integer :row_number, null: false
      t.string :transformation_status, null: false
      t.string :transformation_error
      t.integer :patient_health_identifier_number
      t.string :patient_health_identifier_number_province
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :phone
      t.string :email
      t.date :dob
      t.string :sex
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :province
      t.string :postal_code
      t.string :source_hash
      t.string :address_target_hash

      t.timestamps
    end

    execute "ALTER TABLE transformed_patient_data SET UNLOGGED"

    add_index :transformed_patient_data,
      [ :raw_patient_data_id ],
      unique: true
  end
end
