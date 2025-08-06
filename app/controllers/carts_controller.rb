# frozen_string_literal: true

class CartsController < ApplicationController
  include CartOperations

  before_action :find_or_create_cart, only: [:create]
  before_action :set_cart, only: %i[show add_item remove_item]
  before_action :set_cart_item, only: %i[add_item remove_item]

  def show
    render json: @cart, status: :ok
  end

  def create
    ActiveRecord::Base.transaction do
      check_if_product_exists(cart_params[:product_id])
      check_if_product_exists_in_cart(cart_params[:product_id])
      add_product_to_cart(cart_params[:product_id], cart_params[:quantity].to_i)
    end

    render json: @cart, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :bad_request
  end

  def add_item
    if cart_params[:quantity].to_i.positive?
      increment_cart_item_quantity(@cart_item, cart_params[:quantity].to_i)
      render json: @cart, status: :ok
    else
      render json: { error: I18n.t('carts.errors.quantity_must_be_positive') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :bad_request
  end

  def remove_item
    @cart_item.destroy!

    if @cart.cart_items.empty?
      @cart.destroy!
      session[:cart_id] = nil
      render json: { message: I18n.t('carts.messages.cart_removed_empty') }, status: :ok
    else
      render json: @cart, status: :ok
    end
  rescue StandardError => e
    render json: { error: e }, status: :bad_request
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id])
    return if @cart.present?

    render json: { error: I18n.t('carts.errors.cart_not_found') }, status: :not_found
  end

  def find_or_create_cart
    @cart = Cart.find_by(id: session[:cart_id]) || Cart.create.tap do |cart|
      session[:cart_id] = cart.id
    end
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find_by(product_id: cart_params[:product_id])
    render json: { error: I18n.t('carts.errors.product_not_found_in_cart') }, status: :not_found if @cart_item.blank?
  end

  def cart_params
    params.permit(:product_id, :quantity)
  end
end
