Rails.application.routes.draw do
  root "public/home#index"
  get "up", to: "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  namespace :admin do
    root "dashboard#index"
    resources :users, only: :index
  end

  namespace :public do
    get "planos-pagos", to: "pricing#index", as: :pricing
  end

  namespace :users do
    get "dashboard", to: "dashboard#index"
    get "analytics", to: "analytics#index"

    resources :categories, except: :show
    resources :credit_cards, except: :show
    resources :transactions, except: :show

    resource :subscription, only: :show
  end
end
