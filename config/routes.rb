Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  scope '/v1' do
    post "/debug_jwt", to: "jwt_debugger#debug"
    get "/profile", to: "profiles#show"
    resources :documents, only: %i[create destroy]
    resources :features, only: %i[create destroy]
    resources :tickets, only: [:show] do
      match 'search', on: :collection, via: [:get, :post]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root :controller => 'static', :action => '/public/index.html'
end
