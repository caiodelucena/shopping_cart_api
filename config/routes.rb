# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products

  resource :cart, only: %i[show create], defaults: { format: :json } do
    post 'add_item', to: 'carts#add_item'
    delete ':product_id', to: 'carts#remove_item'
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'rails/health#show'
end
