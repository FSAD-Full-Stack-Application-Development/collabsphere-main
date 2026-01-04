module Api
  module V1
    module Admin
      class ApiLogsController < ApplicationController
        before_action :require_admin

        # GET /api/v1/admin/api_logs
        def index
          @logs = ApiLog.includes(:user)
                        .order(created_at: :desc)
                        .page(params[:page] || 1)
                        .per(params[:per_page] || 50)

          # Apply filters
          @logs = @logs.by_ip(params[:ip]) if params[:ip].present?
          @logs = @logs.by_method(params[:method]) if params[:method].present?
          @logs = @logs.by_path(params[:path]) if params[:path].present?
          @logs = @logs.where(response_status: params[:status]) if params[:status].present?
          @logs = @logs.where(user_id: params[:user_id]) if params[:user_id].present?

          # Filter by date range
          if params[:start_date].present?
            @logs = @logs.where('created_at >= ?', params[:start_date])
          end
          if params[:end_date].present?
            @logs = @logs.where('created_at <= ?', params[:end_date])
          end

          render json: {
            logs: @logs.as_json(
              include: { user: { only: [:id, :full_name, :email] } },
              methods: [:success?, :failed?]
            ),
            meta: {
              current_page: @logs.current_page,
              total_pages: @logs.total_pages,
              total_count: @logs.total_count,
              per_page: @logs.limit_value
            }
          }
        end

        # GET /api/v1/admin/api_logs/stats
        def stats
          period = params[:period] || 'today'
          
          stats = case period
                  when 'today'
                    ApiLog.daily_stats
                  when 'week'
                    ApiLog.weekly_stats
                  when 'month'
                    ApiLog.monthly_stats
                  when 'custom'
                    start_date = params[:start_date] ? Time.parse(params[:start_date]) : 30.days.ago
                    end_date = params[:end_date] ? Time.parse(params[:end_date]) : Time.current
                    ApiLog.stats_for_period(start_date, end_date)
                  else
                    ApiLog.daily_stats
                  end

          render json: {
            period: period,
            stats: stats,
            generated_at: Time.current
          }
        end

        # GET /api/v1/admin/api_logs/:id
        def show
          @log = ApiLog.find(params[:id])
          render json: @log.as_json(
            include: { user: { only: [:id, :full_name, :email] } },
            methods: [:success?, :failed?]
          )
        end

        # DELETE /api/v1/admin/api_logs/cleanup
        def cleanup
          days = params[:days]&.to_i || 30
          cutoff_date = days.days.ago
          
          deleted_count = ApiLog.where('created_at < ?', cutoff_date).delete_all
          
          render json: { 
            message: "Deleted #{deleted_count} log entries older than #{days} days",
            deleted_count: deleted_count
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
