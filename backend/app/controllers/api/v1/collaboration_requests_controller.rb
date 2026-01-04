module Api
  module V1
    class CollaborationRequestsController < ApplicationController
      before_action :set_project
      before_action :set_request, only: [:approve, :reject]
      
      # GET /api/v1/projects/:id/collab
      # List all collaboration requests for a project
      def index
        # Owner/admin can see all requests, users can see only their own
        if @project.owner_id == current_user.id || current_user.system_role == 'admin'
          @requests = @project.collaboration_requests.where(status: 'pending').includes(:user).recent
        else
          @requests = @project.collaboration_requests.where(user_id: current_user.id, status: 'pending').recent
        end
        
        # Pagination
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        limit = params[:limit].to_i > 0 ? params[:limit].to_i : 20
        
        @requests = @requests.page(page).per(limit)
        
        render json: {
          requests: @requests.as_json(
            include: {
              user: { only: [:id, :full_name, :email, :avatar_url] }
            }
          ),
          meta: {
            current_page: page,
            total_pages: @requests.total_pages,
            total_count: @requests.total_count
          }
        }
      end
      
      # POST /api/v1/projects/:id/collab/request
      # Create a collaboration request
      def create
        # Check if user is already a collaborator
        if @project.collaborations.exists?(user_id: current_user.id)
          return render json: { error: 'You are already a collaborator on this project' }, status: :unprocessable_entity
        end
        
        # Check if there's already a pending request
        existing_request = @project.collaboration_requests.find_by(user_id: current_user.id, status: 'pending')
        if existing_request
          return render json: { error: 'You already have a pending request for this project' }, status: :unprocessable_entity
        end
        
        @request = @project.collaboration_requests.build(
          user_id: current_user.id,
          message: params[:message]
        )
        
        if @request.save
          # Create notification for project owner
          NotificationService.collaboration_requested(@request)
          
          render json: {
            message: 'Collaboration request sent successfully',
            request: @request.as_json(
              include: {
                user: { only: [:id, :full_name, :email, :avatar_url] }
              }
            )
          }, status: :created
        else
          render json: { errors: @request.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/projects/:id/collab/approve
      # Approve a collaboration request
      def approve
        authorize_project_owner!
        
        begin
          @request.approve!
          
          # Create notification for requester
          NotificationService.collaboration_approved(@request)
          
          render json: {
            message: 'Request approved successfully',
            request: @request.reload.as_json(
              include: {
                user: { only: [:id, :full_name, :email, :avatar_url] }
              }
            )
          }, status: :ok
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/projects/:id/collab/reject
      # Reject a collaboration request
      def reject
        authorize_project_owner!
        
        if @request.reject!
          # Create notification for requester
          NotificationService.collaboration_rejected(@request)
          
          render json: {
            message: 'Request rejected',
            request: @request.as_json(
              include: {
                user: { only: [:id, :full_name, :email, :avatar_url] }
              }
            )
          }, status: :ok
        else
          render json: { errors: @request.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_project
        @project = Project.find(params[:project_id])
      end
      
      def set_request
        user_id = params[:user_id]
        @request = @project.collaboration_requests.find_by!(user_id: user_id, status: 'pending')
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Pending collaboration request not found' }, status: :not_found
      end
      
      def authorize_project_owner!
        unless @project.owner_id == current_user.id || current_user.system_role == 'admin'
          render json: { error: 'Only project owner can approve/reject requests' }, status: :forbidden
        end
      end
    end
  end
end
