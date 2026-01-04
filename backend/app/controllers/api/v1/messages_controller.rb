module Api
  module V1
    class MessagesController < ApplicationController
      before_action :set_message, only: [:show, :update]

      def index
        # Get all messages (sent + received) for current user
        @messages = Message.where('sender_id = ? OR receiver_id = ?', current_user.id, current_user.id)
                          .includes(:sender, :receiver, :project)
                          .order(created_at: :desc)

        # Apply filters
        @messages = @messages.where(project_id: params[:project_id]) if params[:project_id].present?
        @messages = @messages.where(sender_id: params[:user_id]) if params[:user_id].present?
        @messages = @messages.where(is_read: false) if params[:unread] == 'true'

        # Pagination - support both 'limit' and 'per_page' parameters
        page = params[:page] || 1
        per_page = params[:limit] || params[:per_page] || 20
        @messages = @messages.page(page).per(per_page)

        render json: {
          messages: @messages.as_json(
            include: {
              sender: { only: [:id, :full_name, :avatar_url] },
              receiver: { only: [:id, :full_name, :avatar_url] },
              project: { only: [:id, :title] }
            }
          ),
          pagination: {
            current_page: @messages.current_page,
            total_pages: @messages.total_pages,
            total_count: @messages.total_count,
            per_page: per_page.to_i
          }
        }
      end

      # GET /api/v1/messages/:project_id
      # Fetch paginated chat history for a specific project
      def project_messages
        project_id = params[:project_id]
        
        # Verify user has access to this project (member or owner)
        project = Project.find(project_id)
        unless project.owner_id == current_user.id || project.collaborators.include?(current_user)
          render json: { error: 'Unauthorized - You are not a member of this project' }, status: :forbidden
          return
        end

        # Get messages for this project where current user is sender or receiver
        @messages = Message.where(project_id: project_id)
                          .where('sender_id = ? OR receiver_id = ?', current_user.id, current_user.id)
                          .includes(:sender, :receiver)
                          .order(created_at: :desc)

        # Pagination
        page = params[:page] || 1
        limit = params[:limit] || 20
        @messages = @messages.page(page).per(limit)

        render json: {
          messages: @messages.as_json(
            include: {
              sender: { only: [:id, :full_name, :avatar_url] },
              receiver: { only: [:id, :full_name, :avatar_url] }
            }
          ),
          pagination: {
            current_page: @messages.current_page,
            total_pages: @messages.total_pages,
            total_count: @messages.total_count,
            per_page: limit.to_i
          }
        }
      end

      def unread_count
        count = current_user.received_messages.unread.count
        render json: { unread_count: count }
      end

      # PATCH /api/v1/messages/:id/read
      # Mark a specific message as read
      def mark_as_read
        @message = Message.find(params[:id])
        
        # Only the receiver can mark a message as read
        unless @message.receiver_id == current_user.id
          render json: { error: 'Unauthorized - Only the receiver can mark a message as read' }, status: :forbidden
          return
        end

        if @message.update(is_read: true)
          render json: {
            message: 'Message marked as read',
            message_id: @message.id,
            is_read: @message.is_read
          }
        else
          render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: @message.as_json(
          include: {
            sender: { only: [:id, :full_name, :avatar_url] },
            receiver: { only: [:id, :full_name, :avatar_url] },
            project: { only: [:id, :title] }
          }
        )
      end

      def create
        @message = current_user.sent_messages.build(message_params)
        @message.sent_at = Time.current
        
        if @message.save
          render json: @message, status: :created
        else
          render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @message.receiver_id == current_user.id
          if @message.update(is_read: true)
            render json: @message
          else
            render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      private

      def set_message
        @message = Message.find(params[:id])
        unless @message.sender_id == current_user.id || @message.receiver_id == current_user.id
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      def message_params
        params.require(:message).permit(:receiver_id, :project_id, :content)
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
