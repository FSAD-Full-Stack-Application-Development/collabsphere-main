module Api
  module V1
    class DashboardController < ApplicationController
      skip_before_action :require_login, only: [:statistics]

      # GET /api/v1/dashboard/statistics
      def statistics
        # Normalize case for aggregations
        users_by_country = User.where.not(country: [nil, ''])
                                .group("LOWER(country)")
                                .count
                                .transform_keys(&:titleize)

        users_by_university = User.where.not(university: [nil, ''])
                                   .group("LOWER(university)")
                                   .count
                                   .transform_keys(&:titleize)

        users_by_department = User.where.not(department: [nil, ''])
                                   .group("LOWER(department)")
                                   .count
                                   .transform_keys(&:titleize)

        # Most used tags
        most_used_tags = Tag.joins(:project_tags)
                           .group('tags.id', 'tags.tag_name')
                           .select('tags.*, COUNT(project_tags.id) as usage_count')
                           .order('usage_count DESC')
                           .limit(10)
                           .map { |tag| { name: tag.tag_name, count: tag.usage_count.to_i } }

        # Most active users (considering owned projects and collaborations)
        most_active_users = User.left_joins(:owned_projects, :collaborations)
                               .group('users.id')
                               .select('users.*,
                                       COUNT(DISTINCT projects.id) as owned_projects_count,
                                       COUNT(DISTINCT collaborations.id) as collaborations_count,
                                       (COUNT(DISTINCT projects.id) + COUNT(DISTINCT collaborations.id)) as total_activity')
                               .order('total_activity DESC')
                               .limit(10)

        active_users_data = most_active_users.map do |user|
          {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            country: user.country,
            university: user.university,
            department: user.department,
            owned_projects_count: user.owned_projects_count.to_i,
            collaborations_count: user.collaborations_count.to_i,
            total_activity: user.total_activity.to_i
          }
        end

        render json: {
          users_by_country: users_by_country,
          users_by_university: users_by_university.sort_by { |k, v| -v }.first(10).to_h,
          users_by_department: users_by_department.sort_by { |k, v| -v }.first(10).to_h,
          most_used_tags: most_used_tags,
          most_active_users: active_users_data,
          total_projects: Project.count,
          total_users: User.count,
          total_collaborations: Collaboration.count,
          total_funding: Fund.sum(:amount).to_f
        }
      end
    end
  end
end
