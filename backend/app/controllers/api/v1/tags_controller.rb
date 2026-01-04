module Api
  module V1
    class TagsController < ApplicationController
      skip_before_action :authorize_request, only: [:index, :show]

      def index
        @tags = Tag.all.order(:tag_name)
        render json: @tags
      end

      

      def show
        @tag = Tag.find(params[:id])
        @projects = @tag.projects.where(visibility: 'public').includes(:owner, :project_stat)
        
        render json: {
          tag: @tag,
          projects: @projects.as_json(
            include: {
              owner: { only: [:id, :full_name] },
              project_stat: { only: [:total_views, :total_votes] }
            }
          )
        }
      end

      def create
        @tag = Tag.find_or_create_by(tag_name: params[:tag_name]&.downcase)
        
        if @tag.persisted?
          render json: @tag, status: :created
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
