# frozen_string_literal: true

module CartOperations
  extend ActiveSupport::Concern

  private

  def add_product_to_cart(product_id, quantity)
    @cart.cart_items.build(product_id: product_id, quantity: quantity)
    @cart.save!
  end

  def increment_cart_item_quantity(cart_item, quantity)
    cart_item.quantity += quantity
    cart_item.save!
  end

  def check_if_product_exists(product_id)
    product = Product.find_by(id: product_id)
    raise StandardError, I18n.t('carts.errors.product_not_found') unless product
  end

  def check_if_product_exists_in_cart(product_id)
    @cart_item = @cart.cart_items.find_by(product_id: product_id)
    raise StandardError, I18n.t('carts.errors.product_already_in_cart') if @cart_item
  end
end 