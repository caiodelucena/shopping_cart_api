require 'sidekiq-scheduler'

class MarkCartAsAbandonedJob
  include Sidekiq::Job

  queue_as :default

  def perform
    mark_abandoned_carts
    delete_abandoned_carts
  end

  def mark_abandoned_carts
    carts = Cart.find_inactive_carts_for_abandonment

    return if carts.empty?

    carts.update_all(status: :abandoned)
  end

  def delete_abandoned_carts
    carts = Cart.find_expired_abandoned_carts

    return if carts.empty?

    carts.find_each do |cart|
      cart.remove_if_abandoned
    rescue StandardError => e
      Rails.logger.error "Failed to remove abandoned cart #{cart.id}: #{e.message}"
    end
  end
end
