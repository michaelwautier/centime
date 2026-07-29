Rails.application.routes.draw do
  draw(:hotwire_native)
  mount_avo
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords"
  }

  root "dashboards#show"
  resource :dashboard, only: :show
  resource :reports, only: :show
  resources :transactions
  resources :categories, except: :show
  resources :categorization_rules, only: [ :index, :create, :destroy ]

  resource :subscription, only: :show do
    post :checkout
    get :success
    get :billing_portal
  end

  get "bank_connections/callback" => "bank_connections/callbacks#show", as: :bank_connections_callback
  resources :bank_connections, only: [ :index, :new, :create, :destroy ] do
    member { post :sync }
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
