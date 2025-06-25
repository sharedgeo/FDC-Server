Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  post "/debug_jwt", to: "jwt_debugger#debug"
  get "user/me", to: "users#me"
  post "user/documents", to: "users#create_documents"
  delete "user/documents", to: "users#delete_documents"
  post "user/features", to: "users#create_features"
  delete "user/features", to: "users#delete_features"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
