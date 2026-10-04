class CreateRawPatientData < ActiveRecord::Migration[8.1]
  def change
    create_table :raw_patient_data do |t|
      t.references :data_migration, null: false, foreign_key: true
      t.integer :row_number, null: false
      t.string :health_identifier
      t.string :health_identifier_province
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :phone
      t.string :email
      t.string :address_1
      t.string :address_2
      t.string :address_province
      t.string :address_city
      t.string :address_postal_code
      t.string :date_of_birth
      t.string :sex
      t.string :source_hash
      t.datetime :created_at, null: false
    end

    execute "ALTER TABLE raw_patient_data SET UNLOGGED"

    add_index :raw_patient_data,
      [ :data_migration_id, :row_number ],
      unique: true
  end
end
