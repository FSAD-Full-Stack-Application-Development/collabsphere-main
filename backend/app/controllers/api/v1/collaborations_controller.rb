module Api
  module V1
    class CollaborationsController < ApplicationController
  before_action :set_project
  before_action :set_collaboration, only: [:update, :destroy]
  # Allow self-join on public projects; otherwise restrict to owner/admin
  # Only restrict create, update, destroy to owner/admin
  before_action :authorize_project_owner, only: [:create, :update, :destroy]

      # GET /api/v1/projects/:project_id/collaborations
      def index
        @collaborations = @project.collaborations.includes(:user)
        render json: @collaborations.as_json(
          include: { user: { only: [:id, :full_name, :email, :avatar_url] } }
        )
      end

      # POST /api/v1/projects/:project_id/collaborations
      def create
        # Default role to viewer if not provided
        attrs = collaboration_params
        attrs[:project_role] ||= 'viewer'

        @collaboration = @project.collaborations.build(attrs)
        
        if @collaboration.save
          render json: @collaboration, status: :created
        else
          render json: { errors: @collaboration.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/projects/:project_id/collaborations/:id
      def update
        if @collaboration.update(collaboration_params)
          render json: @collaboration
        else
          render json: { errors: @collaboration.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/projects/:project_id/collaborations/:id
      def destroy
        @collaboration.destroy
        render json: { message: 'Collaborator removed' }, status: :ok
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def set_collaboration
        @collaboration = @project.collaborations.find(params[:id])
      end

      def collaboration_params
        params.require(:collaboration).permit(:user_id, :project_role)
      end

      def authorize_project_owner
        # Owner or admin can always proceed
        return if @project.owner_id == current_user.id || current_user.system_role == 'admin'

        # For create action, allow a user to join themselves on public projects
        if action_name == 'create'
          requested_user_id = params.dig(:collaboration, :user_id).to_i
          if requested_user_id == current_user.id && @project.visibility == 'public'
            return
          end
        end

        render json: { error: 'Only project owner can manage collaborations' }, status: :forbidden
      end
    end
  end
end
