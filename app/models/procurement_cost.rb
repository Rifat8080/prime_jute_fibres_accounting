class ProcurementCost < ApplicationRecord
  belongs_to :costable, polymorphic: true
end
