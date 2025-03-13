Rails.application.routes.draw do
  apipie
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :users, only: [:index, :show, :create, :update, :destroy]

  namespace :api do
    namespace :v1 do

      resource :auth, only: [] do
        post 'register', to: 'authentication#register'
        post 'login', to: 'authentication#login'
        delete 'logout', to: 'authentication#logout'
      end

      get 'users/profile', to: 'users#profile'
      delete 'users', to: 'users#destroy'
      resources :users, only: [:index, :show, :update, :destroy]

      resources :projects, only: [:index, :show, :create, :update, :destroy] do
        resources :tasks, only: [:index, :create, :show, :update, :destroy]

        resources :project_memberships, only: [:index, :create]

        delete 'members/:id', to: 'project_memberships#destroy', as: 'remove_member'
        delete 'members', to: 'project_memberships#destroy', as: 'leave_project'
      end
    end
  end


end
