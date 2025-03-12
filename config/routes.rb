Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :users, only: [:index, :show, :create, :update, :destroy]


  namespace :api do
    namespace :v1 do
      get 'profile', to: 'users#profile'
      post 'auth/register', to: 'authentication#register'
      post 'auth/login', to: 'authentication#login'
      delete 'auth/logout', to: 'authentication#logout'
      delete 'users', to: 'users#destroy_me'

      resources :users, only: [:index, :show, :update]

      get 'projects/owned', to: 'projects#owned'
      get 'projects/joined', to: 'projects#joined'

      resources :projects, only: [:show, :create, :update, :destroy] do
        resources :tasks, only: [:index, :create, :show, :update, :destroy]
        resources :project_memberships, only: [:index, :create, :destroy], controller: 'project_memberships' do
          collection do
            delete 'leave', to: 'project_memberships#leave' # Defines DELETE /api/v1/projects/:project_id/project_memberships/leave
          end
        end
      end

      get 'projects/:project_id/my_tasks', to: 'tasks#my_tasks'
    end
  end



end
