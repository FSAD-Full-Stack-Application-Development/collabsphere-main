module Api
  module V1
    class CommentsController < ApplicationController
      # POST /api/v1/projects/:project_id/comments/:id/like
      def like
        @comment.likes ||= 0
        @comment.likes += 1
        @comment.save!
        
        # Send notification to comment author
        NotificationService.comment_liked(@comment, current_user)
        
        render json: { likes: @comment.likes }, status: :ok
      end

      # POST /api/v1/projects/:project_id/comments/:id/unlike
      def unlike
        @comment.likes ||= 0
        @comment.likes -= 1 if @comment.likes > 0
        @comment.save!
        render json: { likes: @comment.likes }, status: :ok
      end
      before_action :set_project
      before_action :set_comment, only: [:update, :destroy, :report, :hide, :unhide, :like, :unlike]

      # POST /api/v1/projects/:project_id/comments/:id/report
      def report
        reason = params[:reason] || 'Inappropriate content'
        @comment.reports.create!(reporter: current_user, reason: reason)
        render json: { message: 'Comment reported' }, status: :ok
      end

      # POST /api/v1/projects/:project_id/comments/:id/hide
      def hide
        if current_user.system_role == 'admin'
          @comment.hide!(reason: params[:reason] || 'Hidden by admin', admin: current_user)
          render json: { message: 'Comment hidden' }, status: :ok
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      # POST /api/v1/projects/:project_id/comments/:id/unhide
      def unhide
        if current_user.system_role == 'admin'
          @comment.unhide!
          render json: { message: 'Comment unhidden' }, status: :ok
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end
      # GET /api/v1/projects/:project_id/comments
      def index
        @comments = @project.comments
                           .includes(:user)
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(params[:per_page] || 50)
        render json: @comments.as_json(
          include: { 
            user: { only: [:id, :full_name, :avatar_url] },
            replies: { 
              include: { user: { only: [:id, :full_name, :avatar_url] } },
              methods: [:author, :text, :timestamp]
            }
          }
        ), meta: pagination_meta(@comments)
      end

      # POST /api/v1/projects/:project_id/comments
      def create
        @comment = @project.comments.build(comment_params)
        @comment.user = current_user
        if @comment.save
          # Update project stats
          @project.project_stat&.increment!(:total_comments)
          
          # Reload with associations for notification
          @comment.reload
          
          # Send notification to project owner
          NotificationService.project_commented(@comment)
          
          render json: @comment.as_json(
            methods: [:author, :text, :timestamp],
            include: { user: { only: [:id, :full_name, :avatar_url] } }
          ), status: :created
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/projects/:project_id/comments/:id
      def update
        if @comment.user_id == current_user.id || current_user.system_role == 'admin'
          if @comment.update(comment_params)
            render json: @comment
          else
            render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      # DELETE /api/v1/projects/:project_id/comments/:id
      def destroy
        if @comment.user_id == current_user.id || current_user.system_role == 'admin'
          @comment.destroy
          @project.project_stat&.decrement!(:total_comments)
          render json: { message: 'Comment deleted' }, status: :ok
        else
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def set_comment
        @comment = @project.comments.includes(:user, :project).find(params[:id])
      end

      def comment_params
        params.require(:comment).permit(:content, :parent_id)
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
