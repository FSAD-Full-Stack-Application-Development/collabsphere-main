module Api
  module V1
    module Admin
      class AuditLogsController < ApplicationController
        before_action :require_admin

        # GET /api/v1/admin/audit_logs
        def index
          logs = AuditLog.includes(:user)
                        .recent
                        .page(params[:page] || 1)
                        .per(params[:per_page] || 50)

          # Apply filters
          logs = logs.by_user(params[:user_id]) if params[:user_id].present?
          logs = logs.by_action(params[:action]) if params[:action].present?
          logs = logs.by_resource(params[:resource_type], params[:resource_id]) if params[:resource_type].present?
          logs = logs.where('created_at >= ?', params[:start_date]) if params[:start_date].present?
          logs = logs.where('created_at <= ?', params[:end_date]) if params[:end_date].present?

          render json: {
            data: logs.as_json(include: { user: { only: [:id, :full_name, :email] } }),
            meta: {
              total: logs.total_count,
              page: logs.current_page,
              per_page: logs.limit_value,
              total_pages: logs.total_pages
            }
          }
        end

        # GET /api/v1/admin/audit_logs/stats
        def stats
          render json: {
            total_actions: AuditLog.count,
            actions_today: AuditLog.where('created_at >= ?', Date.today).count,
            actions_this_week: AuditLog.where('created_at >= ?', 1.week.ago).count,
            by_action: AuditLog.group(:action).count,
            by_admin: AuditLog.joins(:user)
                              .where(users: { system_role: 'admin' })
                              .group('users.full_name')
                              .count
                              .transform_keys { |k| k || 'Unknown' }
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
