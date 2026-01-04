module Api
  module V1
    class FundingRequestsController < ApplicationController
      before_action :authorize_request
      before_action :set_project
      before_action :set_funding_request, only: [:verify, :reject]
      before_action :authorize_owner, only: [:verify, :reject]
      
      # GET /api/projects/:project_id/fund
      # List funding requests (owner sees all, users see their own)
      def index
        if @project.owner_id == @current_user.id
          # Owner sees all requests
          @requests = @project.funding_requests.recent
        else
          # Users see only their own requests
          @requests = @project.funding_requests.where(funder_id: @current_user.id).recent
        end
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 20
        
        @requests = @requests.page(page).per(per_page)
        
        render json: {
          funding_requests: @requests.as_json(
            include: {
              funder: { only: [:id, :full_name, :email] },
              verifier: { only: [:id, :full_name] }
            }
          ),
          pagination: {
            current_page: @requests.current_page,
            per_page: @requests.limit_value,
            total_pages: @requests.total_pages,
            total_count: @requests.total_count
          }
        }, status: :ok
      end
      
      # POST /api/projects/:project_id/fund/request
      # Submit a funding request
      def create
        # Check if user already has a pending request
        existing_request = @project.funding_requests.pending.find_by(funder_id: @current_user.id)
        
        if existing_request
          return render json: { 
            error: 'You already have a pending funding request for this project' 
          }, status: :unprocessable_entity
        end
        
        @funding_request = @project.funding_requests.build(funding_request_params)
        @funding_request.funder = @current_user
        @funding_request.status = 'pending'
        
        if @funding_request.save
          # Create notification for project owner
          NotificationService.funding_requested(@funding_request)
          
          render json: {
            message: 'Funding request submitted successfully',
            funding_request: @funding_request.as_json(
              include: {
                funder: { only: [:id, :full_name, :email] }
              }
            )
          }, status: :created
        else
          render json: { errors: @funding_request.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end
      
      # POST /api/projects/:project_id/fund/verify
      # Verify (approve) a funding request - creates Fund and updates project total
      def verify
        unless @funding_request.pending?
          return render json: { 
            error: 'Only pending funding requests can be verified' 
          }, status: :unprocessable_entity
        end
        
        begin
          @funding_request.verify!(@current_user)
          
          # Create notification for funder
          NotificationService.funding_verified(@funding_request)
          
          render json: {
            message: 'Funding request verified successfully',
            funding_request: @funding_request.reload.as_json(
              include: {
                funder: { only: [:id, :full_name, :email] },
                verifier: { only: [:id, :full_name] }
              }
            ),
            project: {
              id: @project.id,
              current_funding: @project.reload.current_funding
            }
          }, status: :ok
        rescue => e
          render json: { error: "Failed to verify funding request: #{e.message}" }, 
                 status: :unprocessable_entity
        end
      end
      
      # POST /api/projects/:project_id/fund/reject
      # Reject a funding request
      def reject
        unless @funding_request.pending?
          return render json: { 
            error: 'Only pending funding requests can be rejected' 
          }, status: :unprocessable_entity
        end
        
        if @funding_request.reject!(@current_user)
          # Create notification for funder
          NotificationService.funding_rejected(@funding_request)
          
          render json: {
            message: 'Funding request rejected successfully',
            funding_request: @funding_request.reload.as_json(
              include: {
                funder: { only: [:id, :full_name, :email] },
                verifier: { only: [:id, :full_name] }
              }
            )
          }, status: :ok
        else
          render json: { errors: @funding_request.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end
      
      private
      
      def set_project
        @project = Project.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Project not found' }, status: :not_found
      end
      
      def set_funding_request
        @funding_request = @project.funding_requests.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funding request not found' }, status: :not_found
      end
      
      def authorize_owner
        unless @project.owner_id == @current_user.id
          render json: { error: 'Only project owner can verify or reject funding requests' }, 
                 status: :forbidden
        end
      end
      
      def funding_request_params
        params.require(:funding_request).permit(:amount, :note)
      end
    end
  end
end
