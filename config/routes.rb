Rails.application.routes.draw do
  root "public/home#index"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  namespace :public do
    get "planos-pagos", to: "pricing#index", as: :pricing
  end

  namespace :users do
    get "dashboard", to: "dashboard#index"

    resources :categories
    resources :credit_cards
    resources :transactions

    resource :subscription, only: %i[show create destroy]
    get "analytics", to: "analytics#index"
  end
end