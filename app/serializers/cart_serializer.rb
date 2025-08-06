# frozen_string_literal: true

class CartSerializer < ActiveModel::Serializer
  attributes :id, :products, :total_price
  has_many :cart_items, key: :products, serializer: CartItemSerializer
end 