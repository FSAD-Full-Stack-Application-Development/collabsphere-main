module Api
  module V1
    module Admin
      class LeaderboardController < ApplicationController
        before_action :require_admin

        # GET /api/v1/admin/leaderboard/filter_options
        def filter_options
          render json: {
            countries: User.where.not(country: [nil, '']).select("DISTINCT INITCAP(LOWER(country)) as country").map(&:country).sort,
            universities: User.where.not(university: [nil, '']).select("DISTINCT INITCAP(LOWER(university)) as university").map(&:university).sort,
            departments: User.where.not(department: [nil, '']).select("DISTINCT INITCAP(LOWER(department)) as department").map(&:department).sort
          }
        end

        # GET /api/v1/admin/leaderboard/departments_by_university?university=MIT
        def departments_by_university
          university = params[:university]
          departments = User.where(university: university)
                           .where.not(department: [nil, ''])
                           .distinct
                           .pluck(:department)
                           .sort
          render json: { departments: departments }
        end

        # GET /api/v1/admin/leaderboard/universities_by_country?country=USA
        def universities_by_country
          country = params[:country]
          universities = User.where(country: country)
                            .where.not(university: [nil, ''])
                            .distinct
                            .pluck(:university)
                            .sort
          render json: { universities: universities }
        end

        # GET /api/v1/admin/leaderboard/most_viewed_projects
        def most_viewed_projects
          projects = apply_filters(Project.joins(:project_stat, :owner))
                      .order('project_stats.total_views DESC')
                      .limit(params[:limit] || 10)
                      .includes(:owner, :project_stat, :tags)

          render json: projects.as_json(
            include: {
              owner: { only: [:id, :full_name, :email, :country, :university, :department] },
              project_stat: { only: [:total_views, :total_votes, :total_comments] },
              tags: { only: [:id, :tag_name] }
            }
          )
        end

        # GET /api/v1/admin/leaderboard/most_voted_projects
        def most_voted_projects
          projects = apply_filters(Project.joins(:project_stat, :owner))
                      .order('project_stats.total_votes DESC')
                      .limit(params[:limit] || 10)
                      .includes(:owner, :project_stat, :tags)

          render json: projects.as_json(
            include: {
              owner: { only: [:id, :full_name, :email, :country, :university, :department] },
              project_stat: { only: [:total_views, :total_votes, :total_comments] },
              tags: { only: [:id, :tag_name] }
            }
          )
        end

        # GET /api/v1/admin/leaderboard/most_commented_projects
        def most_commented_projects
          projects = apply_filters(Project.joins(:project_stat, :owner))
                      .order('project_stats.total_comments DESC')
                      .limit(params[:limit] || 10)
                      .includes(:owner, :project_stat, :tags)

          render json: projects.as_json(
            include: {
              owner: { only: [:id, :full_name, :email, :country, :university, :department] },
              project_stat: { only: [:total_views, :total_votes, :total_comments] },
              tags: { only: [:id, :tag_name] }
            }
          )
        end

        # GET /api/v1/admin/leaderboard/most_active_collaborators
        def most_active_collaborators
          users = apply_user_filters(User.all)
                   .left_joins(:collaborations)
                   .group('users.id')
                   .select('users.*, COUNT(collaborations.id) as collaborations_count')
                   .order('collaborations_count DESC')
                   .limit(params[:limit] || 10)

          render json: users.as_json(
            methods: [:collaborations_count],
            include: {
              collaborations: { 
                only: [:id, :project_id, :project_role],
                include: {
                  project: { only: [:id, :title, :status] }
                }
              }
            }
          )
        end

        # GET /api/v1/admin/leaderboard/most_funded_projects
        def most_funded_projects
          projects = apply_filters(Project.joins(:owner).left_joins(:funds))
                      .group('projects.id, users.id')
                      .select('projects.*, COALESCE(SUM(funds.amount), 0) as total_funding, COUNT(funds.id) as funders_count')
                      .order('total_funding DESC')
                      .limit(params[:limit] || 10)

          # Manually build the JSON to include the calculated fields
          result = projects.map do |project|
            project.as_json(
              include: {
                owner: { only: [:id, :full_name, :email, :country, :university, :department] },
                tags: { only: [:id, :tag_name] },
                funds: {
                  only: [:id, :amount, :funded_at],
                  include: {
                    funder: { only: [:id, :full_name] }
                  }
                }
              }
            ).merge(
              'total_funding' => project.total_funding.to_f,
              'funders_count' => project.funders_count.to_i
            )
          end

          render json: result
        end

        # GET /api/v1/admin/leaderboard/top_funders
        def top_funders
          users = apply_user_filters(User.all)
                   .joins('LEFT JOIN funds ON funds.funder_id = users.id')
                   .group('users.id')
                   .select('users.*, COALESCE(SUM(funds.amount), 0) as total_funded, COUNT(DISTINCT funds.id) as projects_funded_count')
                   .order('total_funded DESC')
                   .limit(params[:limit] || 10)

          result = users.map do |user|
            user.as_json(
              only: [:id, :full_name, :email, :country, :university, :department]
            ).merge(
              'total_funded' => user.total_funded.to_f,
              'projects_funded_count' => user.projects_funded_count
            )
          end

          render json: result
        end

        private

        def apply_filters(relation)
          # Filter by owner's country (case-insensitive)
          relation = relation.where("LOWER(users.country) = LOWER(?)", params[:country]) if params[:country].present?
          
          # Filter by owner's university (case-insensitive)
          relation = relation.where("LOWER(users.university) = LOWER(?)", params[:university]) if params[:university].present?
          
          # Filter by owner's department (case-insensitive)
          relation = relation.where("LOWER(users.department) = LOWER(?)", params[:department]) if params[:department].present?
          
          relation
        end

        def apply_user_filters(relation)
          # Filter by country (case-insensitive)
          relation = relation.where("LOWER(country) = LOWER(?)", params[:country]) if params[:country].present?
          
          # Filter by university (case-insensitive)
          relation = relation.where("LOWER(university) = LOWER(?)", params[:university]) if params[:university].present?
          
          # Filter by department (case-insensitive)
          relation = relation.where("LOWER(department) = LOWER(?)", params[:department]) if params[:department].present?
          
          relation
        end

        def require_admin
          unless current_user&.system_role == 'admin'
            render json: { error: 'Not authorized' }, status: :forbidden
          end
        end
      end
    end
  end
end
