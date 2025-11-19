Rails.application.routes.draw do
  resources :suppliers
  resources :stock_houses
  resources :jute_purchases
  resources :procurement_costs
  resources :jute_stocks
  resources :stock_movements

  resources :employees
  resources :salaries
  resources :accounts
  resources :transactions
  resources :buyers
  resources :sales_contracts
  resources :shipments
  resources :export_costs
  resources :shipment_documents

  devise_for :users
  get "posts/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "posts#index"
end
