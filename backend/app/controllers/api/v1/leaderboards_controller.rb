module Api
  module V1
    class LeaderboardsController < ApplicationController
      skip_before_action :authorize_request, only: [:projects, :users]

      # GET /api/v1/leaderboards/projects
      def projects
        @top_projects = Project.joins(:project_stat)
                              .where.not(project_stats: { total_votes: nil })
                              .order('project_stats.total_votes DESC')
                              .limit(params[:limit] || 10)
        
        render json: @top_projects.as_json(
          include: {
            owner: { only: [:id, :full_name, :avatar_url] },
            project_stat: { only: [:total_votes, :total_views, :total_comments] }
          }
        )
      end

      # GET /api/v1/leaderboards/users
      def users
        @top_users = User.select('users.*, COUNT(DISTINCT projects.id) as project_count, 
                                  COUNT(DISTINCT comments.id) as comment_count,
                                  COUNT(DISTINCT collaborations.id) as collaboration_count')
                        .left_joins(:owned_projects, :comments, :collaborations)
                        .group('users.id')
                        .order('project_count DESC, comment_count DESC')
                        .limit(params[:limit] || 10)
        
        render json: @top_users.as_json(
          only: [:id, :full_name, :avatar_url, :country, :university],
          methods: [:project_count, :comment_count, :collaboration_count]
        )
      end

      # GET /api/v1/leaderboards/most_viewed
      def most_viewed
        @most_viewed = Project.joins(:project_stat)
                             .where.not(project_stats: { total_views: nil })
                             .order('project_stats.total_views DESC')
                             .limit(params[:limit] || 10)
        
        render json: @most_viewed.as_json(
          include: {
            owner: { only: [:id, :full_name, :avatar_url] },
            project_stat: { only: [:total_views, :total_votes] }
          }
        )
      end
    end
  end
end
