class AddIndexesAndHashToPatientsAndAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :source_hash, :string, null: false
    add_index :addresses, :source_hash, unique: true

    add_index :patients,
      [ :patient_health_identifier_number, :patient_health_identifier_number_province ],
      unique: true,
      where: "is_current = true"
  end
end
