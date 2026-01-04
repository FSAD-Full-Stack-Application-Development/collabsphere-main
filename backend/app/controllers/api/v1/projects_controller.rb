module Api
  module V1
    class ProjectsController < ApplicationController
      before_action :set_project, only: [:show, :update, :destroy, :vote, :unvote]
      before_action :normalize_project_params, only: [:create, :update]
      skip_before_action :authorize_request, only: [:index]

      # GET /api/v1/projects
      def index
        @projects = Project.includes(:owner, :collaborators, :tags, :project_stat)
        
        # Search by title or description
        if params[:q].present?
          @projects = @projects.where(
            'title ILIKE ? OR description ILIKE ?',
            "%#{params[:q]}%", "%#{params[:q]}%"
          )
        end
        
        # Filter by status
        @projects = @projects.where(status: params[:status]) if params[:status].present?
        
        # Filter by visibility
        @projects = @projects.where(visibility: params[:visibility]) if params[:visibility].present?
        
        # Filter by tags
        if params[:tags].present?
          tag_names = params[:tags].split(',')
          @projects = @projects.joins(:tags).where(tags: { tag_name: tag_names }).distinct
        end
        
        # Filter by owner university
        @projects = @projects.joins(:owner).where(users: { university: params[:university] }) if params[:university].present?
        
        # Filter by owner department
        @projects = @projects.joins(:owner).where(users: { department: params[:department] }) if params[:department].present?
        
        # Sort options
        case params[:sort]
        when 'votes'
          @projects = @projects.joins(:project_stat).order('project_stats.total_votes DESC NULLS LAST')
        when 'views'
          @projects = @projects.joins(:project_stat).order('project_stats.total_views DESC NULLS LAST')
        when 'oldest'
          @projects = @projects.order(created_at: :asc)
        else
          @projects = @projects.order(created_at: :desc)
        end
        
        @projects = @projects.page(params[:page]).per(params[:per_page] || 25)
        
        render json: {
          data: @projects.as_json(
            only: [:id, :title, :description, :status, :visibility, :show_funds, :funding_goal, :current_funding, :created_at],
            include: {
              owner: { only: [:id, :full_name, :email, :country, :university, :department] },
              collaborators: { only: [:id, :full_name, :email] },
              tags: { only: [:id, :tag_name] },
              project_stat: { only: [:total_views, :total_votes, :total_comments] }
            },
            methods: [:vote_count]
          ),
          meta: pagination_meta(@projects)
        }
      end

      # GET /api/v1/projects/:id
      def show
        # Increment view count
        @project.project_stat&.increment!(:total_views)
        
        @project = Project.includes(
          :owner,
          :tags,
          :collaborators,
          :project_stat,
          { funds: :funder },
          { comments: [:user, :replies] }
        ).find(params[:id])

        # Only top-level comments (parent_id: nil), with nested replies
        top_level_comments = @project.comments.select { |c| c.parent_id.nil? }

        render json: @project.as_json(
          only: [:id, :title, :description, :status, :visibility, :show_funds, :funding_goal, :current_funding, :created_at],
          include: {
            owner: { only: [:id, :full_name, :email, :country, :university, :department] },
            tags: { only: [:id, :tag_name] },
            collaborators: { only: [:id, :full_name, :email] },
            project_stat: { only: [:total_views, :total_votes, :total_comments] },
            # funds: {
            #   include: {
            #     funder: { only: [:id, :full_name] }
            #   }
            # },
          },
          methods: [:vote_count]
        ).merge(
          comments: top_level_comments.as_json(
            only: [:id, :likes],
            methods: [:author, :text, :timestamp],
            include: {
              user: { only: [:id, :full_name] },
              replies: {
                only: [:id, :likes],
                methods: [:author, :text, :timestamp],
                include: {
                  user: { only: [:id, :full_name] },
                  replies: {
                    only: [:id, :likes],
                    methods: [:author, :text, :timestamp],
                    include: {
                      user: { only: [:id, :full_name] },
                      replies: {
                        only: [:id, :likes],
                        methods: [:author, :text, :timestamp],
                        include: {
                          user: { only: [:id, :full_name] }
                        }
                      }
                    }
                  }
                }
              }
            }
          ),
          user_voted: current_user ? @project.votes.exists?(user_id: current_user.id) : false
        )
      end

      # POST /api/v1/projects
      def create
        @project = current_user.owned_projects.build(project_params)

        if @project.save
          process_tags if params[:tags].present?
          render json: @project.as_json(include: { tags: { only: [:id, :tag_name] } }), status: :created
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if can_modify_project?
          if @project.update(project_params)
            process_tags if params[:tags].present?
            render json: @project
          else
            render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Unauthorized to update this project' }, status: :forbidden
        end
      end

      # DELETE /api/v1/projects/:id
      def destroy
        if @project.owner_id == current_user.id || current_user.system_role == 'admin'
          @project.destroy
          render json: { message: 'Project deleted successfully' }, status: :ok
        else
          render json: { error: 'Unauthorized to delete this project' }, status: :forbidden
        end
      end

      # POST /api/v1/projects/:id/vote
      def vote
        vote_type = params[:vote_type] || 'up' # 'up' or 'down'
        
        existing_vote = Vote.find_by(project: @project, user: current_user)
        
        if existing_vote
          existing_vote.update(vote_type: vote_type)
          vote = existing_vote
        else
          vote = Vote.create(project: @project, user: current_user, vote_type: vote_type)
        end
        
        # Send notification for new upvotes (reload to ensure associations are loaded)
        if vote && !existing_vote
          vote.reload
          NotificationService.project_voted(vote)
        end
        
        update_vote_stats
        render json: { message: 'Vote recorded', vote_count: @project.project_stat.total_votes }
      end

      # DELETE /api/v1/projects/:id/unvote
      def unvote
        vote = Vote.find_by(project: @project, user: current_user)
        if vote
          vote.destroy
          update_vote_stats
          render json: { message: 'Vote removed', vote_count: @project.project_stat.total_votes }
        else
          render json: { error: 'No vote found to remove' }, status: :not_found
        end
      end

      private

      # Create or attach tags by name
      def process_tags
        tag_names = params[:tags]&.map(&:strip)&.reject(&:blank?) || []
        tags = tag_names.map do |name|
          Tag.find_or_create_by(tag_name: name)
        end
        @project.tags = tags
      end

      def set_project
        @project = Project.find(params[:id])
      end

      def project_params
        params.require(:project).permit(:title, :description, :status, :visibility, :show_funds, :funding_goal)
      end

      # Normalize incoming project params to match model validations
      # - Accept common synonyms and casing for status
      # - Normalize visibility to lowercase values
      def normalize_project_params
        return unless params[:project].is_a?(ActionController::Parameters) || params[:project].is_a?(Hash)

        status = params[:project][:status]
        if status.present?
          key = status.to_s.strip.downcase
          mapped = case key
                   when 'planning', 'ideation' then 'Ideation'
                   when 'ongoing', 'in-progress', 'in_progress', 'active' then 'Ongoing'
                   when 'completed', 'complete', 'done', 'finished' then 'Completed'
                   else
                     # If unknown, keep original but titleize common lowercase inputs
                     status.to_s.strip.capitalize
                   end
          params[:project][:status] = mapped
        end

        visibility = params[:project][:visibility]
        if visibility.present?
          params[:project][:visibility] = visibility.to_s.strip.downcase
        end
      end

      def can_modify_project?
        @project.owner_id == current_user.id || 
        @project.collaborations.exists?(user_id: current_user.id, project_role: [0, 1]) ||
        current_user.system_role == 'admin'
      end

      def update_vote_stats
        up_votes = @project.votes.where(vote_type: 'up').count
        down_votes = @project.votes.where(vote_type: 'down').count
        @project.project_stat&.update(total_votes: up_votes - down_votes)
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
