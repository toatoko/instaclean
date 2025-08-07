Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login", to: "authentication#login"
      post "auth/register", to: "authentication#register"
      delete "auth/logout", to: "authentication#logout"
      get "auth/me", to: "authentication#me"

      # Users (consolidated with followers/following)
      resources :users, param: :username, only: [ :index, :show, :update ] do
        member do
          post :follow
          delete :unfollow
          get :followers
          get :following
        end
        collection do
          get :suggested
        end
      end

      # Posts
      resources :posts, only: [ :index, :show, :create, :update, :destroy ] do
        resources :comments, only: [ :index, :create, :destroy ]
        member do
          post :toggle_like
        end
      end

      # Messages/Conversations (Keep separate - they serve different purposes)
      resources :conversations, only: [ :index, :show ] do
        resources :messages, only: [ :create ]
      end

      # Notifications
      resources :notifications, only: [ :index ] do
        member do
          patch :mark_as_read
        end
        collection do
          patch :mark_all_as_read
        end
      end

      # Search
      get "search", to: "search#index"

      # Blocking
      resources :blocks, only: [ :index, :create, :destroy ]

      # Reports
      resources :reports, only: [ :create ]
    end
  end

  # Public report creation
  resources :reports, only: [ :create ]

  # Admin routes
  namespace :admin do
    # Root dashboard
    root to: "admin#dashboard"
    get "dashboard", to: "admin#dashboard"
    get "posts",     to: "admin#posts"
    get "comments",  to: "admin#comments"

    # Admin::UsersController
    resources :users, param: :username do
      member do
        patch :toggle_admin
        patch :resolve_all_reports, to: "reports#resolve_all"
      end
      resources :reports, only: [ :index ], controller: "reports"
    end

    # Admin::ReportsController
    resources :reports, only: [ :index, :show ] do
      member do
        patch :resolve
        patch :dismiss
      end
    end

    # Admin::PostsController
    resources :posts, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        patch :resolve_all_reports, to: "reports#resolve_all"
      end
      resources :reports, only: [ :index ], controller: "reports"
    end

    # Admin::CommentsController
    resources :comments, only: [ :index, :show, :destroy ] do
      member do
        patch :resolve_all_reports, to: "reports#resolve_all"
      end
      resources :reports, only: [ :index ], controller: "reports"
    end

    # Admin::BansController
    resources :users, param: :username, only: [] do
      resource :ban, controller: "bans", only: [ :create, :destroy ]
    end
    # Admin::SearchController
    resources :search, only: [ :index ]
  end

  # Posts & Comments
  resources :posts do
    resources :comments, only: [ :create, :destroy ]
    member do
      post :toggle_like
    end
  end

  # Blocked Users Management
  get "/blocked_users", to: "blocks#index", as: "blocked_users"

  # Users and Profiles
  devise_for :users
  resources :users, param: :username, only: [] do
    resource :block, controller: "blocks", only: [ :create, :destroy ]     # User blocking
  end

  get "/dashboard", to: "users#index"
  get "/profile(/:username)", to: "users#profile", as: :profile
  get "/users/:username",     to: "users#show", as: :user_profile
  get "/suggested_followers", to: "users#all_users"
  post "/users/:username/follow",   to: "users#follow",   as: :user_follows
  delete "/users/:username/unfollow", to: "users#unfollow", as: :user_unfollows

  # Messaging
  resources :messages, only: [ :index ] do
    member do
      patch :mark_as_read
    end
  end
  get "messages/:username", to: "messages#show", as: "conversation"
  post "messages/:username", to: "messages#create"
  # Notifications
  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_as_read  # For marking all as read
      delete :delete_read  # Delete all read notifications
      delete :delete_all   # Delete all notifications
    end
  end
  # Search
  get "search", to: "search#index"

  # Root
  root "users#index"
end
