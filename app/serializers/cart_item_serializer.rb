# frozen_string_literal: true

class CartItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :quantity, :unit_price, :total_price
  belongs_to :cart
  belongs_to :product

  def name
    object.product.name
  end

  def unit_price
    object.product.price
  end

  def total_price
    object.product.price * object.quantity
  end
end