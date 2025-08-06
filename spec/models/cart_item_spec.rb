# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CartItem, type: :model do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }

  describe 'associations' do
    it { is_expected.to belong_to(:cart).touch(:last_interaction_at) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
  end

  describe 'touch behavior' do
    it 'updates cart last_interaction_at when cart_item is created' do
      original_last_interaction_at = cart.last_interaction_at
      sleep(1)

      create(:cart_item, cart: cart, product: product)
      cart.reload

      expect(cart.last_interaction_at).to be > original_last_interaction_at
    end

    it 'updates cart last_interaction_at when cart_item is updated' do
      cart_item = create(:cart_item, cart: cart, product: product)
      cart.reload
      original_last_interaction_at = cart.last_interaction_at
      sleep(1)

      cart_item.update(quantity: 5)
      cart.reload

      expect(cart.last_interaction_at).to be > original_last_interaction_at
    end

    it 'updates cart last_interaction_at when cart_item is destroyed' do
      cart_item = create(:cart_item, cart: cart, product: product)
      cart.reload
      original_last_interaction_at = cart.last_interaction_at
      sleep(1)

      cart_item.destroy
      cart.reload

      expect(cart.last_interaction_at).to be > original_last_interaction_at
    end
  end

  describe 'callbacks' do
    it 'updates cart total price after create' do
      expect(cart.total_price).to eq(0)

      create(:cart_item, cart: cart, product: product, quantity: 2)

      expect(cart.reload.total_price).to eq(product.price * 2)
    end

    it 'updates cart total price after update' do
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart.total_price).to eq(product.price * 2)

      cart_item.update(quantity: 3)

      expect(cart.reload.total_price).to eq(product.price * 3)
    end

    it 'updates cart total price after destroy' do
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart.total_price).to eq(product.price * 2)

      cart_item.destroy

      expect(cart.reload.total_price).to eq(0)
    end
  end
end
