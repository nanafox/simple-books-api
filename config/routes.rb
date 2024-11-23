# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :books, only: %i[index show destroy update create]
      resources :authors, only: %i[index] do
        resources :books, only: %i[index show destroy create]
      end
    end
  end

  # API Health and Stats
  get "/api/status", to: "api_health#index"
  get "/api/stats", to: "api_health#stats"

  match "*unmatched", to: "application#invalid_route", via: :all
end
