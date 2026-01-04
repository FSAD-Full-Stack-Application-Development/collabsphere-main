module Api
  module V1
    module Admin
      class AnalyticsController < ApplicationController
        before_action :require_admin

        # GET /api/v1/admin/analytics
        def index
          analytics = {
            overview: {
              total_users: User.count,
              total_projects: Project.count,
              total_comments: Comment.count,
              total_votes: Vote.count,
              total_messages: Message.count
            },
            user_metrics: {
              active_users_today: User.where('updated_at >= ?', Date.today).count,
              active_users_this_week: User.where('updated_at >= ?', 1.week.ago).count,
              new_users_today: User.where('created_at >= ?', Date.today).count,
              new_users_this_week: User.where('created_at >= ?', 1.week.ago).count,
              new_users_this_month: User.where('created_at >= ?', 1.month.ago).count,
              users_by_country: User.where.not(country: [nil, '']).group("LOWER(country)").count.transform_keys(&:titleize).sort_by { |k, v| -v }.first(10).to_h,
              users_by_university: User.where.not(university: [nil, '']).group("LOWER(university)").count.transform_keys(&:titleize).sort_by { |k, v| -v }.first(10).to_h,
              users_by_department: User.where.not(department: [nil, '']).group("LOWER(department)").count.transform_keys(&:titleize).sort_by { |k, v| -v }.first(10).to_h
            },
            project_metrics: {
              projects_by_status: Project.group(:status).count,
              projects_by_visibility: Project.group(:visibility).count,
              projects_created_today: Project.where('created_at >= ?', Date.today).count,
              projects_created_this_week: Project.where('created_at >= ?', 1.week.ago).count,
              projects_created_this_month: Project.where('created_at >= ?', 1.month.ago).count,
              average_collaborators_per_project: (Collaboration.count.to_f / Project.count).round(2)
            },
            engagement_metrics: {
              total_comments: Comment.count,
              comments_today: Comment.where('created_at >= ?', Date.today).count,
              comments_this_week: Comment.where('created_at >= ?', 1.week.ago).count,
              total_votes: Vote.count,
              votes_today: Vote.where('created_at >= ?', Date.today).count,
              votes_this_week: Vote.where('created_at >= ?', 1.week.ago).count,
              average_comments_per_project: (Comment.count.to_f / Project.count).round(2),
              average_votes_per_project: (Vote.count.to_f / Project.count).round(2)
            },
            top_performers: {
              most_active_users: User.select('users.*, COUNT(DISTINCT projects.id) as owned_count, COUNT(DISTINCT collaborations.id) as collab_count, (COUNT(DISTINCT projects.id) + COUNT(DISTINCT collaborations.id)) as project_count')
                                     .left_joins(:owned_projects)
                                     .left_joins(:collaborations)
                                     .group('users.id')
                                     .order('project_count DESC')
                                     .limit(5)
                                     .map { |u| { id: u.id, full_name: u.full_name, email: u.email, project_count: u.project_count.to_i, owned_count: u.owned_count.to_i, collab_count: u.collab_count.to_i } },
              most_viewed_projects: Project.joins(:project_stat)
                                          .order('project_stats.total_views DESC')
                                          .limit(5)
                                          .as_json(only: [:id, :title], include: { project_stat: { only: [:total_views] } }),
              most_voted_projects: Project.joins(:project_stat)
                                         .order('project_stats.total_votes DESC')
                                         .limit(5)
                                         .as_json(only: [:id, :title], include: { project_stat: { only: [:total_votes] } })
            },
            tag_metrics: {
              most_used_tags: Tag.joins(:project_tags)
                                .group('tags.id', 'tags.tag_name')
                                .select('tags.tag_name, COUNT(project_tags.id) as usage_count')
                                .order('usage_count DESC')
                                .limit(10)
                                .map { |tag| { name: tag.tag_name, count: tag.usage_count.to_i } }
            }
          }
          
          render json: analytics
        end

        # GET /api/v1/admin/analytics/growth
        def growth
          last_30_days = (0..29).map do |n|
            date = n.days.ago.to_date
            {
              date: date,
              new_users: User.where(created_at: date.beginning_of_day..date.end_of_day).count,
              new_projects: Project.where(created_at: date.beginning_of_day..date.end_of_day).count,
              new_comments: Comment.where(created_at: date.beginning_of_day..date.end_of_day).count
            }
          end.reverse
          
          render json: {
            period: 'last_30_days',
            data: last_30_days
          }
        end

        private

        def require_admin
          unless current_user&.system_role == 'admin'
            render json: { error: 'Admin access required' }, status: :forbidden
          end
        end
      end
    end
  end
end
