class CreateTransformedAddressData < ActiveRecord::Migration[8.1]
  def change
    create_table :transformed_address_data do |t|
      t.references :data_migration, null: false
      t.references :raw_patient_data, null: false

      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :province
      t.string :postal_code

      t.timestamps
    end

    execute "ALTER TABLE transformed_address_data SET UNLOGGED"
  end
end
