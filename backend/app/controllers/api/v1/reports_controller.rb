module Api
  module V1
    class ReportsController < ApplicationController
      before_action :set_reportable, only: [:create]

      # POST /api/v1/reports
      def create
        report = current_user.reports_made.build(report_params)
        report.reportable = @reportable
        
        if report.save
          # Mark the reportable as reported
          mark_as_reported(@reportable)
          
          # Notify admins about the new report
          notify_admins(report)
          
          render json: {
            message: 'Report submitted successfully',
            report: report_json(report)
          }, status: :created
        else
          render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/reports/my_reports
      def my_reports
        reports = current_user.reports_made
                              .includes(:reportable)
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(params[:limit] || 20)
        
        render json: {
          reports: reports.map { |r| report_json(r) },
          meta: pagination_meta(reports)
        }
      end

      private

      def set_reportable
        reportable_type = params[:reportable_type]
        reportable_id = params[:reportable_id]
        
        case reportable_type
        when 'User'
          @reportable = User.find(reportable_id)
        when 'Project'
          @reportable = Project.find(reportable_id)
        when 'Comment'
          @reportable = Comment.find(reportable_id)
        else
          render json: { error: 'Invalid reportable type' }, status: :bad_request
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Reportable not found' }, status: :not_found
      end

      def report_params
        params.require(:report).permit(:reason, :description)
      end

      def mark_as_reported(reportable)
        reportable.update(is_reported: true) if reportable.respond_to?(:is_reported)
      end

      def notify_admins(report)
        User.where(system_role: 'admin').find_each do |admin|
          NotificationService.content_reported(
            user: admin,
            report: report
          )
        end
      end

      def report_json(report)
        {
          id: report.id,
          reason: report.reason,
          description: report.description,
          status: report.status,
          reportable: report.reportable_details,
          reporter: {
            id: report.reporter.id,
            full_name: report.reporter.full_name,
            email: report.reporter.email
          },
          resolved_by: report.resolved_by ? {
            id: report.resolved_by.id,
            full_name: report.resolved_by.full_name
          } : nil,
          resolved_at: report.resolved_at,
          created_at: report.created_at,
          updated_at: report.updated_at
        }
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end
