Rails.application.routes.draw do
  devise_for :users
  
  # Posts routes
  get "posts/index"
  get "home" => "posts#index", as: :home
  get "dashboard" => "posts#dashboard", as: :dashboard
  root "posts#index"

  resources :suppliers
  resources :stock_houses
  resources :jute_purchases
  resources :jute_stocks do
    resources :processing_batches, only: [ :index, :new, :create ]
  end
  resources :procurement_costs
  resources :stock_movements
  resources :processing_batches
  resources :products

  resources :salaries
  resources :accounts
  resources :accounts do
    resources :transactions
  end
  resources :buyers
  resources :sales_contracts
  resources :shipments
  resources :shipment_documents
  resources :users

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
