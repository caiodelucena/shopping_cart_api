require 'rails_helper'

RSpec.describe Cart, type: :model do
  describe '#associations' do
    it { is_expected.to have_many(:cart_items).dependent(:destroy) }
    it { is_expected.to have_many(:products).through(:cart_items) }
  end

  describe '#enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, abandoned: 1) }
  end

  describe '#scopes' do
    let!(:active_cart) { create(:cart, status: :active, last_interaction_at: 4.hours.ago) }
    let!(:recent_active_cart) { create(:cart, status: :active, last_interaction_at: 1.hour.ago) }
    let!(:abandoned_cart) { create(:cart, status: :abandoned, last_interaction_at: 5.hours.ago) }
    let!(:expired_abandoned_cart) { create(:cart, status: :abandoned, last_interaction_at: 8.days.ago) }

    describe '.find_inactive_carts_for_abandonment' do
      it 'returns carts that are not abandoned and inactive for more than 3 hours' do
        expect(described_class.find_inactive_carts_for_abandonment).to include(active_cart)
        expect(described_class.find_inactive_carts_for_abandonment).not_to include(recent_active_cart, abandoned_cart, expired_abandoned_cart)
      end
    end

    describe '.find_expired_abandoned_carts' do
      it 'returns abandoned carts that have been inactive for more than 7 days' do
        expect(described_class.find_expired_abandoned_carts).to include(expired_abandoned_cart)
        expect(described_class.find_expired_abandoned_carts).not_to include(active_cart, recent_active_cart, abandoned_cart)
      end
    end
  end

  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart).not_to be_valid
      expect(cart.errors[:total_price]).to include('must be greater than or equal to 0')
    end
  end

  describe '#mark_as_abandoned' do
    let(:cart) { create(:cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      cart.update(last_interaction_at: 3.hours.ago)
      expect { cart.mark_as_abandoned }.to change(cart, :abandoned?).from(false).to(true)
    end
  end

  describe '#remove_if_abandoned' do
    let(:cart) { create(:cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      cart.mark_as_abandoned
      expect { cart.remove_if_abandoned }.to change(described_class, :count).by(-1)
    end
  end

  describe '#update_total_price' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }

    it 'updates the total price based on cart items' do
      create(:cart_item, cart: cart, product: product, quantity: 2)
      cart.update(total_price: 0)

      expect { cart.update_total_price }.to change(cart, :total_price).from(0).to(20.0)
    end

    it 'does not update total price if there are no cart items' do
      expect { cart.update_total_price }.not_to change(cart, :total_price)
    end
  end
end
