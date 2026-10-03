class Patient < ApplicationRecord
  belongs_to :address, optional: true
  belongs_to :data_migration, optional: true
end
