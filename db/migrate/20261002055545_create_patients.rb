class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :patient_health_identifier_number
      t.string :patient_health_identifier_number_province
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :phone
      t.string :email
      t.date :dob
      t.string :sex
      t.references :address, null: true, foreign_key: true
      t.references :data_migration, null: true, foreign_key: true
      t.string :source_hash
      t.datetime :valid_from
      t.datetime :valid_to
      t.boolean :is_current

      t.timestamps
    end
  end
end
