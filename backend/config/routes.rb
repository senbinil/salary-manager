Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Application endpoints. Authentication is served by Rodauth, which bypasses
  # this router under the same /api/v1 prefix.
  namespace :api do
    namespace :v1 do
      get "me", to: "me#show", as: :me

      resources :compensation_plans, only: :index
      resources :countries, only: :index
      resources :departments, only: :index
      resources :designations, only: :index
      resources :employees, only: %i[index show]
      resources :salary_components, only: :index
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
