class CartItem < ApplicationRecord
  belongs_to :cart, touch: :last_interaction_at
  belongs_to :product

  after_commit :update_cart_total_price, on: %i[create update destroy]

  validates :quantity, numericality: { greater_than: 0 }

  private

  def update_cart_total_price
    return if cart.blank?

    cart.update_total_price
  end
end