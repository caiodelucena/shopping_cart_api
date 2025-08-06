class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  enum status: { active: 0, abandoned: 1 }

  scope :find_inactive_carts_for_abandonment, lambda {
    where('carts.status != ? AND last_interaction_at < ?', statuses[:abandoned], abandonment_period)
  }

  scope :find_expired_abandoned_carts, lambda {
    where('carts.status = ? AND last_interaction_at < ?', statuses[:abandoned], remove_cart_after_period)
  }

  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  def mark_as_abandoned
    abandoned!
  end

  def remove_if_abandoned
    destroy if abandoned?
  end

  def update_total_price
    update(total_price: cart_items.joins(:product).sum('cart_items.quantity * products.price'))
  end

  def self.abandonment_period
    3.hours.ago
  end

  def self.remove_cart_after_period
    7.days.ago
  end
end
