class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :province
      t.string :postal_code

      t.timestamps
    end
  end
end
