class AddIndexToPatientsSourceHash < ActiveRecord::Migration[8.1]
  def change
    add_index :patients,
      [ :source_hash ],
      unique: true,
      where: "is_current = true"
  end
end
