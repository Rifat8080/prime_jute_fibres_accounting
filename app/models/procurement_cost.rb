class ProcurementCost < ApplicationRecord
  belongs_to :costable, polymorphic: true

  validates :cost_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_date, presence: true

  after_save :update_costable_total_amount
  after_destroy :update_costable_total_amount

  private

  def update_costable_total_amount
    if costable.is_a?(JutePurchase)
      costable.save # This will trigger the before_save callback in JutePurchase
    end
  end
end
