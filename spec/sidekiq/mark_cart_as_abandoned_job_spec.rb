# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    let!(:active_cart) { create(:cart, status: :active, last_interaction_at: 4.hours.ago) }
    let!(:abandoned_cart) { create(:cart, status: :abandoned, last_interaction_at: 8.days.ago) }
    let!(:recent_cart) { create(:cart, status: :active, last_interaction_at: 1.hour.ago) }

    it 'marks inactive carts as abandoned' do
      expect do
        described_class.new.perform
      end.to change { active_cart.reload.status }.from('active').to('abandoned')
    end

    it 'removes expired abandoned carts' do
      expect do
        described_class.new.perform
      end.to change { Cart.where(id: abandoned_cart.id).exists? }.from(true).to(false)
    end

    it 'does not change recent carts' do
      expect do
        described_class.new.perform
      end.not_to(change { recent_cart.reload.status })
    end

    it 'handles empty cart list gracefully' do
      Cart.destroy_all
      expect { described_class.new.perform }.not_to raise_error
    end

    it 'processes multiple carts correctly' do
      old_cart = create(:cart, status: :active, last_interaction_at: 5.hours.ago)
      very_old_cart = create(:cart, status: :abandoned, last_interaction_at: 10.days.ago)

      expect do
        described_class.new.perform
      end.to change { old_cart.reload.status }.from('active').to('abandoned')
        .and change { Cart.where(id: very_old_cart.id).exists? }.from(true).to(false)
    end

    it 'does not remove recently abandoned carts' do
      recently_abandoned = create(:cart, status: :abandoned, last_interaction_at: 2.days.ago)

      expect do
        described_class.new.perform
      end.not_to change { Cart.where(id: recently_abandoned.id).exists? }
    end
  end

  describe '#mark_abandoned_carts' do
    it 'marks only inactive carts' do
      inactive_cart = create(:cart, status: :active, last_interaction_at: 4.hours.ago)
      active_cart = create(:cart, status: :active, last_interaction_at: 1.hour.ago)

      described_class.new.mark_abandoned_carts
      expect(inactive_cart.reload.status).to eq('abandoned')
      expect(active_cart.reload.status).to eq('active')
    end

    it 'does not mark already abandoned carts' do
      already_abandoned = create(:cart, status: :abandoned, last_interaction_at: 4.hours.ago)

      expect do
        described_class.new.mark_abandoned_carts
      end.not_to change { already_abandoned.reload.status }
    end
  end

  describe '#delete_abandoned_carts' do
    it 'removes only expired abandoned carts' do
      expired_cart = create(:cart, status: :abandoned, last_interaction_at: 8.days.ago)
      recent_abandoned = create(:cart, status: :abandoned, last_interaction_at: 2.days.ago)

      described_class.new.delete_abandoned_carts
      expect(Cart.where(id: expired_cart.id)).not_to exist
      expect(Cart.where(id: recent_abandoned.id)).to exist
    end

    it 'handles errors during cart removal gracefully' do
      cart = create(:cart, status: :abandoned, last_interaction_at: 8.days.ago)
      allow(Rails.logger).to receive(:error)
      allow_any_instance_of(Cart).to receive(:remove_if_abandoned).and_raise(StandardError, 'Removal failed')

      described_class.new.delete_abandoned_carts

      expected_message = I18n.t('jobs.mark_cart_as_abandoned.messages.failed_to_remove_cart',
                                cart_id: cart.id,
                                error_message: 'Removal failed')
      expect(Rails.logger).to have_received(:error).with(expected_message)
    end
  end
end
