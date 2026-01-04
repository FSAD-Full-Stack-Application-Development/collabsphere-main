module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authorize_request
      before_action :set_notification, only: [:mark_as_read, :mark_as_unread, :destroy]
      
      # GET /api/v1/notifications
      def index
        @notifications = @current_user.notifications.recent
        
        # Filter by read status
        if params[:unread] == 'true'
          @notifications = @notifications.unread
        elsif params[:read] == 'true'
          @notifications = @notifications.read
        end
        
        # Filter by type
        if params[:type].present?
          @notifications = @notifications.for_type(params[:type])
        end
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 20
        
        @notifications = @notifications.page(page).per(per_page)
        
        render json: {
          notifications: @notifications.as_json(
            include: {
              actor: { only: [:id, :full_name, :email] }
            },
            methods: []
          ),
          unread_count: @current_user.notifications.unread.count,
          pagination: {
            current_page: @notifications.current_page,
            per_page: @notifications.limit_value,
            total_pages: @notifications.total_pages,
            total_count: @notifications.total_count
          }
        }, status: :ok
      end
      
      # POST /api/v1/notifications/:id/read
      def mark_as_read
        @notification.mark_as_read!
        render json: { 
          message: 'Notification marked as read',
          notification: @notification 
        }, status: :ok
      end
      
      # POST /api/v1/notifications/:id/unread
      def mark_as_unread
        @notification.mark_as_unread!
        render json: { 
          message: 'Notification marked as unread',
          notification: @notification 
        }, status: :ok
      end
      
      # POST /api/v1/notifications/read_all
      def mark_all_as_read
        Notification.mark_all_read_for_user(@current_user)
        render json: { 
          message: 'All notifications marked as read',
          unread_count: 0
        }, status: :ok
      end
      
      # DELETE /api/v1/notifications/:id
      def destroy
        @notification.destroy
        render json: { message: 'Notification deleted' }, status: :ok
      end
      
      # GET /api/v1/notifications/unread_count
      def unread_count
        count = @current_user.notifications.unread.count
        render json: { unread_count: count }, status: :ok
      end
      
      private
      
      def set_notification
        @notification = @current_user.notifications.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end
    end
  end
end
