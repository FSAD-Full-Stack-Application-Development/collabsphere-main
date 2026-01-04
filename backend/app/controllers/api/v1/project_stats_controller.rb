module Api
  module V1
    class ProjectStatsController < ApplicationController
      skip_before_action :authorize_request

      def show
        @project = Project.find(params[:id])
        @stats = @project.project_stat || ProjectStat.create(project: @project, total_views: 0, total_votes: 0, total_comments: 0)
        
        render json: {
          project_id: @project.id,
          project_title: @project.title,
          stats: @stats
        }
      end
    end
  end
end
