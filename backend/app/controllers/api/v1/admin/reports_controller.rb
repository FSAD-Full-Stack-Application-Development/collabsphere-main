module Api
  module V1
    module Admin
      class ReportsController < ApplicationController
        include Auditable
        before_action :require_admin
        before_action :set_report, only: [:show, :resolve, :dismiss]
        
        def index
          @reports = Report.includes(:reporter, :reportable, :resolved_by)
                           .order(created_at: :desc)
          
          # Filter by status
          @reports = @reports.where(status: params[:status]) if params[:status].present?
          
          # Filter by type
          @reports = @reports.for_type(params[:type]) if params[:type].present?
          
          # Pagination
          @reports = @reports.page(params[:page]).per(params[:per_page] || 25)
          
          render json: {
            data: @reports.as_json(
              include: {
                reporter: { only: [:id, :full_name, :email] },
                resolved_by: { only: [:id, :full_name] }
              },
              methods: [:reportable_details]
            ),
            meta: pagination_meta(@reports)
          }
        end
        
        def show
          render json: @report.as_json(
            include: {
              reporter: { only: [:id, :full_name, :email] },
              reportable: {},
              resolved_by: { only: [:id, :full_name] }
            }
          )
        end
        
        def resolve
          note = params[:note] || 'Report marked as resolved'
          @report.update(
            status: 'resolved',
            resolved_by: current_user,
            resolved_at: Time.current
          )
          
          log_audit(
            action: 'report_resolved',
            resource_type: 'Report',
            resource_id: @report.id,
            details: "Resolved report ##{@report.id} for #{@report.reportable_type} ##{@report.reportable_id}. Note: #{note}"
          )
          
          render json: @report
        end
        
        def dismiss
          note = params[:note] || 'Report dismissed'
          @report.update(
            status: 'dismissed',
            resolved_by: current_user,
            resolved_at: Time.current
          )
          
          log_audit(
            action: 'report_dismissed',
            resource_type: 'Report',
            resource_id: @report.id,
            details: "Dismissed report ##{@report.id} for #{@report.reportable_type} ##{@report.reportable_id}. Note: #{note}"
          )
          
          render json: @report
        end
        
        def stats
          stats = {
            total: Report.count,
            by_status: {
              pending: Report.where(status: 'pending').count,
              reviewing: Report.where(status: 'reviewing').count,
              resolved: Report.where(status: 'resolved').count,
              dismissed: Report.where(status: 'dismissed').count
            },
            by_type: {
              users: Report.for_type('User').count,
              projects: Report.for_type('Project').count,
              comments: Report.for_type('Comment').count,
              tags: Report.for_type('Tag').count
            }
          }
          render json: stats
        end
        
        private
        
        def set_report
          @report = Report.find(params[:id])
        end
        
        def require_admin
          unless current_user&.system_role == 'admin'
            render json: { error: 'Not authorized' }, status: :forbidden
          end
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
