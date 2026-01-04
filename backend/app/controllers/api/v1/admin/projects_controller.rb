module Api
  module V1
    module Admin
      class ProjectsController < ApplicationController
        before_action :require_admin
        before_action :set_project, only: [:show, :feature, :unfeature, :destroy]

        # GET /api/v1/admin/projects
        def index
          @projects = Project.all.includes(:owner, :tags, :project_stat)
          
          # Filter by status
          @projects = @projects.where(status: params[:status]) if params[:status].present?
          
          # Filter by visibility
          @projects = @projects.where(visibility: params[:visibility]) if params[:visibility].present?
          
          # Filter by owner's country
          @projects = @projects.joins(:owner).where(users: { country: params[:owner_country] }) if params[:owner_country].present?
          
          # Filter by owner's university
          @projects = @projects.joins(:owner).where(users: { university: params[:owner_university] }) if params[:owner_university].present?
          
          # Filter by owner's department
          @projects = @projects.joins(:owner).where(users: { department: params[:owner_department] }) if params[:owner_department].present?
          
          # Filter by reported projects (those with at least one report)
          if params[:reported] == 'true'
            @projects = @projects.joins("LEFT JOIN reports ON reports.reportable_type = 'Project' AND reports.reportable_id = projects.id")
                                .where("reports.id IS NOT NULL")
                                .distinct
          end
          
          # Search
          if params[:q].present?
            @projects = @projects.where(
              'title ILIKE ? OR description ILIKE ?',
              "%#{params[:q]}%", "%#{params[:q]}%"
            )
          end
          
          # Sort
          case params[:sort]
          when 'reports'
            @projects = @projects.joins("LEFT JOIN (SELECT reportable_id, COUNT(*) as report_count FROM reports WHERE reportable_type = 'Project' GROUP BY reportable_id) r ON r.reportable_id = projects.id")
                                .order('COALESCE(r.report_count, 0) DESC')
          when 'views'
            @projects = @projects.joins(:project_stat).order('project_stats.total_views DESC NULLS LAST')
          when 'likes'
            @projects = @projects.joins(:project_stat).order('project_stats.total_votes DESC NULLS LAST')
          when 'funded'
            @projects = @projects.joins("LEFT JOIN (SELECT project_id, SUM(amount) as total_funding FROM funds GROUP BY project_id) f ON f.project_id = projects.id")
                                .order('COALESCE(f.total_funding, 0) DESC')
          else
            @projects = @projects.order(created_at: :desc)
          end
          
          @projects = @projects.page(params[:page]).per(params[:per_page] || 25)
          
          render json: {
            data: @projects.as_json(
              include: {
                owner: { only: [:id, :full_name, :email, :country, :university, :department] },
                project_stat: { only: [:total_views, :total_votes, :total_comments] },
                tags: { only: [:id, :tag_name] }
              },
              methods: [:reports_count, :total_funding, :funders_count]
            ),
            meta: pagination_meta(@projects)
          }
        end

        # GET /api/v1/admin/projects/:id
        def show
          render json: @project.as_json(
            include: {
              owner: { only: [:id, :full_name, :email, :country, :university, :department] },
              collaborations: { 
                include: { 
                  user: { only: [:id, :full_name, :email] } 
                },
                methods: [:project_role]
              },
              tags: { only: [:id, :tag_name] },
              comments: { 
                only: [:id, :content, :created_at],
                include: {
                  user: { only: [:id, :full_name] }
                }
              },
              votes: { 
                only: [:id, :vote_type, :created_at],
                include: {
                  user: { only: [:id, :full_name] }
                }
              },
              funds: {
                only: [:id, :amount, :description, :created_at],
                include: {
                  funder: { only: [:id, :full_name, :email] }
                }
              },
              project_stat: {}
            },
            methods: [:reports_count]
          )
        end

        # PUT /api/v1/admin/projects/:id/feature
        def feature
          # Add featured flag to project (requires migration)
          render json: { message: 'Feature functionality requires featured column migration' }, status: :not_implemented
        end

        # PUT /api/v1/admin/projects/:id/unfeature
        def unfeature
          render json: { message: 'Feature functionality requires featured column migration' }, status: :not_implemented
        end

        # DELETE /api/v1/admin/projects/:id
        def destroy
          @project.destroy
          render json: { message: 'Project deleted successfully' }
        end

        # GET /api/v1/admin/projects/stats
        def stats
          stats = {
            total_projects: Project.count,
            by_status: Project.group(:status).count,
            by_visibility: Project.group(:visibility).count,
            total_views: ProjectStat.sum(:total_views),
            total_votes: ProjectStat.sum(:total_votes),
            total_comments: ProjectStat.sum(:total_comments),
            projects_created_today: Project.where('created_at >= ?', Date.today).count,
            projects_created_this_week: Project.where('created_at >= ?', 1.week.ago).count,
            projects_created_this_month: Project.where('created_at >= ?', 1.month.ago).count
          }
          
          render json: stats
        end

        # GET /api/v1/admin/projects/filter_options
        def filter_options
          render json: {
            countries: User.joins(:owned_projects).where.not(country: [nil, '']).distinct.pluck(:country).sort,
            universities: User.joins(:owned_projects).where.not(university: [nil, '']).distinct.pluck(:university).sort,
            departments: User.joins(:owned_projects).where.not(department: [nil, '']).distinct.pluck(:department).sort
          }
        end

        # GET /api/v1/admin/projects/universities_by_country?country=USA
        def universities_by_country
          country = params[:country]
          universities = User.joins(:owned_projects)
                            .where(country: country)
                            .where.not(university: [nil, ''])
                            .distinct
                            .pluck(:university)
                            .sort
          render json: { universities: universities }
        end

        # GET /api/v1/admin/projects/departments_by_university?university=MIT
        def departments_by_university
          university = params[:university]
          departments = User.joins(:owned_projects)
                           .where(university: university)
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

        def set_project
          @project = Project.find(params[:id])
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
