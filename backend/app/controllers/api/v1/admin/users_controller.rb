module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        include Auditable
        before_action :require_admin
        before_action :set_user, only: [:show, :update, :suspend, :activate, :destroy]

        # GET /api/v1/admin/users
        def index
          @users = User.all
          
          # Filter by role
          @users = @users.where(system_role: params[:role]) if params[:role].present?
          
          # Filter by country
          @users = @users.where(country: params[:country]) if params[:country].present?
          
          # Filter by university
          @users = @users.where(university: params[:university]) if params[:university].present?
          
          # Filter by department
          @users = @users.where(department: params[:department]) if params[:department].present?
          
          # Filter by banned status
          @users = @users.where(banned: params[:banned]) if params[:banned].present?
          
          # Filter by reported users (those with at least one report)
          if params[:reported] == 'true'
            @users = @users.joins("LEFT JOIN reports ON reports.reportable_type = 'User' AND reports.reportable_id = users.id")
                          .where("reports.id IS NOT NULL")
                          .distinct
          end
          
          # Search by name or email
          if params[:q].present?
            @users = @users.where(
              'full_name ILIKE ? OR email ILIKE ?',
              "%#{params[:q]}%", "%#{params[:q]}%"
            )
          end
          
          @users = @users.order(created_at: :desc)
                        .page(params[:page])
                        .per(params[:per_page] || 25)
          
          render json: {
            data: @users.as_json(methods: [:reports_count]),
            meta: pagination_meta(@users)
          }
        end

        # GET /api/v1/admin/users/:id
        def show
          render json: @user.as_json(
            include: {
              owned_projects: { 
                only: [:id, :title, :status, :visibility],
                include: {
                  project_stat: { only: [:total_views, :total_votes, :total_comments] }
                }
              },
              collaborations: { 
                only: [:id, :project_id, :project_role],
                include: {
                  project: { only: [:id, :title, :status] }
                }
              },
              funds: {
                include: {
                  project: { only: [:id, :title] }
                }
              },
              comments: { only: [:id, :content, :created_at, :project_id] },
              votes: { only: [:id, :vote_type, :project_id] },
              tags: { only: [:id, :tag_name] }
            },
            methods: [:reports_count]
          )
        end

        # PATCH /api/v1/admin/users/:id
        def update
          if @user.id == current_user.id && user_params[:system_role] && user_params[:system_role] != @user.system_role
            render json: { error: 'Cannot change your own role' }, status: :forbidden
            return
          end

          if @user.update(user_params)
            log_audit(
              action: 'user_updated',
              resource_type: 'User',
              resource_id: @user.id,
              details: "Updated user: #{@user.email}"
            )
            render json: @user
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PUT /api/v1/admin/users/:id/suspend
        def suspend
          @user.update(system_role: 'suspended')
          render json: { message: 'User suspended successfully', user: @user }
        end

        # PUT /api/v1/admin/users/:id/activate
        def activate
          @user.update(system_role: 'user')
          render json: { message: 'User activated successfully', user: @user }
        end

        # DELETE /api/v1/admin/users/:id
        def destroy
          if @user.id == current_user.id
            render json: { error: 'Cannot delete your own account' }, status: :forbidden
            return
          end
          
          user_email = @user.email
          @user.destroy
          
          log_audit(
            action: 'user_deleted',
            resource_type: 'User',
            resource_id: @user.id,
            details: "Deleted user: #{user_email}"
          )
          
          render json: { message: 'User deleted successfully' }
        end

        # GET /api/v1/admin/users/:id/activity
        def activity
          @user = User.find(params[:id])
          
          activity_data = {
            projects_created: @user.owned_projects.count,
            comments_posted: @user.comments.count,
            votes_cast: @user.votes.count,
            collaborations: @user.collaborations.count,
            messages_sent: @user.sent_messages.count,
            recent_projects: @user.owned_projects.order(created_at: :desc).limit(5),
            recent_comments: @user.comments.order(created_at: :desc).limit(10),
            last_active: @user.updated_at
          }
          
          render json: activity_data
        end

        # GET /api/v1/admin/users/filter_options
        def filter_options
          render json: {
            countries: User.where.not(country: [nil, '']).distinct.pluck(:country).sort,
            universities: User.where.not(university: [nil, '']).distinct.pluck(:university).sort,
            departments: User.where.not(department: [nil, '']).distinct.pluck(:department).sort
          }
        end

        # GET /api/v1/admin/users/universities_by_country?country=USA
        def universities_by_country
          country = params[:country]
          universities = User.where(country: country)
                            .where.not(university: [nil, ''])
                            .distinct
                            .pluck(:university)
                            .sort
          render json: { universities: universities }
        end

        # GET /api/v1/admin/users/departments_by_university?university=MIT
        def departments_by_university
          university = params[:university]
          departments = User.where(university: university)
                           .where.not(department: [nil, ''])
                           .distinct
                           .pluck(:department)
                           .sort
          render json: { departments: departments }
        end

        private

        def require_admin
          unless current_user&.system_role == 'admin'
            render json: { error: 'Admin access required' }, status: :forbidden
          end
        end

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(
            :full_name, :email, :system_role, :banned,
            :country, :university, :department, :bio, :avatar_url
          )
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
end
