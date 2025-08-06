# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/carts', type: :request do
  describe 'GET /cart' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }

    context 'when the cart exists' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: cart.id })
      end

      it 'returns the cart with its items', :aggregate_failures do
        get '/cart', as: :json

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['id']).to eq(cart.id)
        expect(response_body['products'].length).to eq(1)
        expect(response_body['products'][0]['id']).to eq(cart_item.id)
        expect(response_body['products'][0]['quantity']).to eq(2)
        expect(response_body['products'][0]['unit_price']).to eq('10.0')
        expect(response_body['products'][0]['total_price']).to eq('20.0')
        expect(response_body['total_price']).to eq('20.0')
      end
    end

    context 'when the cart does not exist' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: nil })
      end

      it 'returns not found error' do
        get '/cart', as: :json

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.cart_not_found'))
      end
    end
  end

  describe 'POST /add_item' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    context 'when the cart exists' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: cart.id })
      end

      context 'when the product already is in the cart' do
        subject do
          post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
          post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        end

        it 'updates the quantity of the existing item in the cart', :aggregate_failures do
          expect { subject }.to change { cart_item.reload.quantity }.by(2)
          response_body = JSON.parse(response.body)

          expect(response_body['id']).to eq(cart.id)
          expect(response_body['products'].length).to eq(1)
          expect(response_body['products'][0]['id']).to eq(cart_item.id)
          expect(response_body['products'][0]['quantity']).to eq(3)
          expect(response_body['products'][0]['unit_price']).to eq('10.0')
          expect(response_body['products'][0]['total_price']).to eq('30.0')
          expect(response_body['total_price']).to eq('30.0')
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when the product is not in the cart' do
        subject do
          post '/cart/add_item', params: { product_id: new_product.id, quantity: 2 }, as: :json
        end

        let(:new_product) { create(:product, price: 20.0) }

        it 'returns not found error' do
          subject
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_not_found_in_cart'))
        end
      end

      context 'when the product does not exist in database' do
        subject do
          post '/cart/add_item', params: { product_id: 999, quantity: 1 }, as: :json
        end

        it 'returns not found error' do
          subject
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_not_found_in_cart'))
        end
      end

      context 'when quantity is zero or negative' do
        subject do
          post '/cart/add_item', params: { product_id: product.id, quantity: 0 }, as: :json
        end

        it 'returns unprocessable entity error', :aggregate_failures do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.quantity_must_be_positive'))
        end
      end

      context 'when parameters are missing' do
        subject do
          post '/cart/add_item', params: { product_id: product.id }, as: :json
        end

        it 'returns unprocessable entity error', :aggregate_failures do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.quantity_must_be_positive'))
        end
      end
    end

    context 'when the cart does not exist' do
      subject do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: nil })
      end

      it 'returns not found error', :aggregate_failures do
        subject
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.cart_not_found'))
      end
    end
  end

  describe 'DELETE /cart/:product_id' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    context 'when the cart exists' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: cart.id })
      end

      context 'when the product exists in the cart' do
        subject do
          delete "/cart/#{product.id}", as: :json
        end

        it 'removes the item from the cart' do
          expect { subject }.to change { cart.cart_items.count }.by(-1)
          expect(response).to have_http_status(:ok)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq(I18n.t('carts.messages.cart_removed_empty'))
        end
      end

      context 'when the cart has multiple items' do
        subject do
          delete "/cart/#{product.id}", as: :json
        end

        let(:other_product) { create(:product, price: 15.0) }
        let!(:other_cart_item) { create(:cart_item, cart: cart, product: other_product, quantity: 1) }

        it 'removes only the specified item from the cart' do
          expect { subject }.to change { cart.cart_items.count }.by(-1)
          expect(response).to have_http_status(:ok)

          response_body = JSON.parse(response.body)
          expect(response_body['id']).to eq(cart.id)
          expect(response_body['products'].length).to eq(1)
          expect(response_body['products'][0]['id']).to eq(other_cart_item.id)
          expect(response_body['total_price']).to eq('15.0')
        end
      end

      context 'when the cart becomes empty after removal' do
        subject do
          delete "/cart/#{product.id}", as: :json
        end

        it 'removes the cart and returns success message' do
          expect { subject }.to change(Cart, :count).by(-1)
          expect(response).to have_http_status(:ok)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq(I18n.t('carts.messages.cart_removed_empty'))
        end
      end

      context 'when the product does not exist in the cart' do
        subject do
          delete "/cart/#{other_product.id}", as: :json
        end

        let(:other_product) { create(:product) }

        it 'returns not found error' do
          subject
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_not_found_in_cart'))
        end
      end

      context 'when the product does not exist in database' do
        subject do
          delete '/cart/999', as: :json
        end

        it 'returns not found error' do
          subject
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_not_found_in_cart'))
        end
      end
    end

    context 'when the cart does not exist' do
      subject do
        delete "/cart/#{product.id}", as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: nil })
      end

      it 'returns not found error' do
        subject
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.cart_not_found'))
      end
    end
  end

  describe 'POST /cart' do
    let(:product) { create(:product, price: 10.0) }

    context 'when creating a new cart' do
      subject do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({})
      end

      it 'creates a new cart with the product' do
        expect { subject }.to change(Cart, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when product does not exist' do
      subject do
        post '/cart', params: { product_id: 999, quantity: 1 }, as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({})
      end

      it 'returns bad request error' do
        subject
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_not_found'))
      end
    end

    context 'when product already exists in cart' do
      subject do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      let(:cart) { create(:cart) }
      let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: cart.id })
      end

      it 'returns bad request error' do
        subject
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('carts.errors.product_already_in_cart'))
      end
    end

    context 'when quantity is zero or negative' do
      subject do
        post '/cart', params: { product_id: product.id, quantity: 0 }, as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({})
      end

      it 'returns bad request error' do
        subject
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when parameters are missing' do
      subject do
        post '/cart', params: { product_id: product.id }, as: :json
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({})
      end

      it 'returns bad request error' do
        subject
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
