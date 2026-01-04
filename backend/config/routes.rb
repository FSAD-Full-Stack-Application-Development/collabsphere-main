Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable for WebSocket connections
  mount ActionCable.server => '/cable'

  # Authentication routes
  post '/auth/register', to: 'authentication#register'
  post '/auth/login', to: 'authentication#login'

  # API v1
  namespace :api do
    namespace :v1, defaults: { format: :json } do
  # Suggestions endpoints for autocomplete
  get 'suggestions/tags', to: 'suggestions#tags'
  get 'suggestions/countries', to: 'suggestions#countries'
  get 'suggestions/universities', to: 'suggestions#universities'
  get 'suggestions/departments', to: 'suggestions#departments'
  get 'suggestions/university_departments', to: 'suggestions#university_departments'
      # User routes
      resources :users, only: [:index, :show, :update, :destroy] do
        collection do
          get 'profile'
          get 'autocomplete/universities'
          get 'autocomplete/countries'
        end
      end
      
      # Profile routes (alias to users for semantic clarity)
      resources :profiles, controller: 'users', only: [:index, :show, :update]

      # Project routes
      resources :projects do
        member do
          post 'vote'
          delete 'vote', action: :unvote
        end
        resources :collaborations, only: [:index, :create, :update, :destroy]
        
        # Collaboration request routes
        post 'collab/request', to: 'collaboration_requests#create'
        post 'collab/approve', to: 'collaboration_requests#approve'
        post 'collab/reject', to: 'collaboration_requests#reject'
        get 'collab', to: 'collaboration_requests#index'
        
        # Funding request routes
        post 'fund/request', to: 'funding_requests#create'
        post 'fund/verify', to: 'funding_requests#verify'
        post 'fund/reject', to: 'funding_requests#reject'
        get 'fund', to: 'funding_requests#index'
        
        resources :comments, only: [:index, :create, :update, :destroy] do
          member do
            post 'report'
            post 'hide'
            post 'unhide'
            post 'like'
            post 'unlike'
          end
        end
        resources :resources, only: [:index, :create, :update, :destroy] do
          member do
            post 'approve'
            post 'reject'
          end
        end
        resources :funds, only: [:index, :create]
      end

      # Tag routes
      resources :tags, only: [:index, :create]
      
      # Dashboard routes
      get 'dashboard/statistics', to: 'dashboard#statistics'
      
      # Leaderboards
      get 'leaderboards/projects', to: 'leaderboards#projects'
      get 'leaderboards/users', to: 'leaderboards#users'
      get 'leaderboards/most_viewed', to: 'leaderboards#most_viewed'
  # Alias for compatibility with existing clients
  get 'leaderboards/top-creators', to: 'leaderboards#users'

      # Message routes
      resources :messages, only: [:index, :create, :show, :update] do
        collection do
          get 'unread_count'
        end
        member do
          patch 'read', to: 'messages#mark_as_read'
        end
      end
      
      # Message history by project (specific endpoint as per spec)
      get 'messages/:project_id', to: 'messages#project_messages'
      
      # Notification routes
      resources :notifications, only: [:index, :destroy] do
        member do
          post 'read', to: 'notifications#mark_as_read'
          post 'unread', to: 'notifications#mark_as_unread'
        end
        collection do
          post 'read_all', to: 'notifications#mark_all_as_read'
          get 'unread_count', to: 'notifications#unread_count'
        end
      end
      
      # Reports
      resources :reports, only: [:create] do
        collection do
          get 'my_reports'
        end
      end

      # Stats
      get 'stats/projects/:id', to: 'project_stats#show'
      
      # Admin namespace
      namespace :admin do
        get 'stats', to: 'dashboard#stats'
        get 'analytics', to: 'analytics#index'
        get 'analytics/growth', to: 'analytics#growth'
        
        resources :audit_logs, only: [:index] do
          collection do
            get 'stats'
          end
        end
        
        resources :users do
          collection do
            get 'filters', to: 'users#filter_options'
            get 'filter_options'
            get 'universities_by_country'
            get 'departments_by_university'
          end
        end
        resources :projects, only: [:index, :show, :update, :destroy] do
          collection do
            get 'filters', to: 'projects#filter_options'
            get 'filter_options'
            get 'universities_by_country'
            get 'departments_by_university'
          end
        end
        resources :tags
        resources :reports do
          member do
            patch 'resolve'
            patch 'dismiss'
          end
          collection do
            get 'stats'
          end
        end
        
        # Moderation routes
        scope module: :admin do
          get 'moderation/reports', to: 'moderation#reports'
          patch 'moderation/reports/:id', to: 'moderation#update_report'
          post 'moderation/reports/:id/resolve', to: 'moderation#resolve_report'
          post 'moderation/users/:id/suspend', to: 'moderation#suspend_user'
          post 'moderation/users/:id/unsuspend', to: 'moderation#unsuspend_user'
          post 'moderation/projects/:id/hide', to: 'moderation#hide_project'
          post 'moderation/projects/:id/unhide', to: 'moderation#unhide_project'
          post 'moderation/comments/:id/hide', to: 'moderation#hide_comment'
          post 'moderation/comments/:id/unhide', to: 'moderation#unhide_comment'
          get 'moderation/stats', to: 'moderation#stats'
        end
        
        # API Logs routes
        resources :api_logs, only: [:index, :show] do
          collection do
            get 'stats'
            delete 'cleanup'
          end
        end
        
        # Database management routes
        post 'database/run_seeds', to: 'database#run_seeds'
        post 'database/reset', to: 'database#reset_database'
        
        # Leaderboard routes
        namespace :leaderboard do
          get 'filter_options'
          get 'universities_by_country'
          get 'departments_by_university'
          get 'most_viewed_projects'
          get 'most_voted_projects'
          get 'most_commented_projects'
          get 'most_active_collaborators'
          get 'most_funded_projects'
          get 'top_funders'
        end
      end
    end
  end
end
