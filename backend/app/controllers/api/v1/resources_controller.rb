module Api
  module V1
    class ResourcesController < ApplicationController
      before_action :set_project
      before_action :set_resource, only: [:update, :destroy, :approve, :reject]

      def index
        # Check if user has access to private project resources
        if @project.visibility == 'private' && !can_access_private_project?
          render json: { error: 'You do not have permission to view resources for this private project' }, status: :forbidden
          return
        end

        if @project.owner_id == current_user.id
          # Owner sees all resources
          @resources = @project.resources.includes(:added_by)
        elsif is_collaborator?
          # Collaborators see all resources (including pending for private projects)
          @resources = @project.resources.includes(:added_by)
        else
          # Others see only approved resources
          @resources = @project.resources.where(status: 'approved').includes(:added_by)
        end
        
        render json: @resources.as_json(
          include: { added_by: { only: [:id, :full_name] } }
        )
      end

      def create
        @resource = @project.resources.build(resource_params)
        @resource.added_by = current_user
        
        if @resource.save
          # Send notification to project owner and collaborators
          NotificationService.resource_added(@resource)
          
          # Create notification for project collaborators
          NotificationService.resource_added(@resource)
          
          render json: @resource, status: :created
        else
          render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if can_modify_resource?
          if @resource.update(resource_params)
            render json: @resource
          else
            render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      def destroy
        if can_delete_resource?
          @resource.destroy
          render json: { message: 'Resource deleted successfully' }, status: :ok
        else
          render json: { error: 'You do not have permission to delete this resource' }, status: :forbidden
        end
      end

      def approve
        if @project.owner_id == current_user.id
          if @resource.update(status: 'approved')
            render json: @resource
          else
            render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Only project owner can approve resources' }, status: :forbidden
        end
      end

      def reject
        if @project.owner_id == current_user.id
          @resource.destroy
          render json: { message: 'Resource rejected and deleted' }, status: :ok
        else
          render json: { error: 'Only project owner can reject resources' }, status: :forbidden
        end
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def set_resource
        @resource = @project.resources.find(params[:id])
      end

      def resource_params
        params.require(:resource).permit(:title, :description, :url)
      end

      def can_modify_resource?
        @resource.added_by_id == current_user.id || 
        @project.owner_id == current_user.id ||
        current_user.system_role == 'admin'
      end

      def can_delete_resource?
        # Resource can be deleted by:
        # 1. The person who added it
        # 2. The project owner
        # 3. An admin
        @resource.added_by_id == current_user.id || 
        @project.owner_id == current_user.id ||
        current_user.system_role == 'admin'
      end

      def is_collaborator?
        @project.collaborations.exists?(user_id: current_user.id)
      end

      def can_access_private_project?
        # For private projects, only owner, collaborators, and admins can access resources
        @project.owner_id == current_user.id ||
        is_collaborator? ||
        current_user.system_role == 'admin'
      end
    end
  end
end
