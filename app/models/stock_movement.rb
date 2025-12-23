class StockMovement < ApplicationRecord
  belongs_to :jute_stock
  belongs_to :source, polymorphic: true, optional: true

  validates :movement_type, presence: true
  validates :quantity_bales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :movement_date, presence: true

  after_create :apply_to_stock
  after_destroy :revert_stock!

  def incoming?
    movement_type == "incoming"
  end

  def outgoing?
    movement_type == "outgoing"
  end

  def transfer?
    movement_type == "transfer"
  end

  private

  def apply_to_stock
    return unless jute_stock

    if incoming?
      jute_stock.increment!(:quantity_bales, quantity_bales || 0)
    elsif outgoing?
      jute_stock.decrement!(:quantity_bales, quantity_bales || 0)
    end
    jute_stock.update(last_updated: movement_date)
  end

  def revert_stock!
    return unless jute_stock

    if incoming?
      jute_stock.decrement!(:quantity_bales, quantity_bales || 0)
    elsif outgoing?
      jute_stock.increment!(:quantity_bales, quantity_bales || 0)
    end
    jute_stock.update(last_updated: Time.current)
  end
end
