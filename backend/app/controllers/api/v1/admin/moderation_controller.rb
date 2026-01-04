module Api
  module V1
    module Admin
      class ModerationController < ApplicationController
        before_action :require_admin
        before_action :set_report, only: [:update_report, :resolve_report]

        # GET /api/v1/admin/moderation/reports
        def reports
          status_filter = params[:status] || 'pending'
          type_filter = params[:type]
          
          reports = Report.includes(:reporter, :reportable, :resolved_by)
                          .order(created_at: :desc)
          
          reports = reports.where(status: status_filter) if status_filter.present?
          reports = reports.for_type(type_filter) if type_filter.present?
          
          reports = reports.page(params[:page]).per(params[:limit] || 20)
          
          render json: {
            reports: reports.map { |r| detailed_report_json(r) },
            meta: pagination_meta(reports),
            stats: report_stats
          }
        end

        # PATCH /api/v1/admin/moderation/reports/:id
        def update_report
          if @report.update(report_update_params)
            render json: {
              message: 'Report updated successfully',
              report: detailed_report_json(@report)
            }
          else
            render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/admin/moderation/reports/:id/resolve
        def resolve_report
          @report.update!(
            status: params[:action_taken] || 'resolved',
            resolved_by: current_user,
            resolved_at: Time.current
          )
          
          render json: {
            message: 'Report resolved successfully',
            report: detailed_report_json(@report)
          }
        end

        # POST /api/v1/admin/moderation/users/:id/suspend
        def suspend_user
          user = User.find(params[:id])
          reason = params[:reason] || 'Violated community guidelines'
          
          user.suspend!(reason: reason, admin: current_user)
          
          NotificationService.user_suspended(
            user: user,
            admin: current_user,
            reason: reason
          )
          
          render json: {
            message: 'User suspended successfully',
            user: moderation_user_json(user)
          }
        end

        # POST /api/v1/admin/moderation/users/:id/unsuspend
        def unsuspend_user
          user = User.find(params[:id])
          user.unsuspend!
          
          NotificationService.user_unsuspended(
            user: user,
            admin: current_user
          )
          
          render json: {
            message: 'User unsuspended successfully',
            user: moderation_user_json(user)
          }
        end

        # POST /api/v1/admin/moderation/projects/:id/hide
        def hide_project
          project = Project.find(params[:id])
          reason = params[:reason] || 'Violated content policy'
          
          project.hide!(reason: reason, admin: current_user)
          
          NotificationService.content_hidden(
            user: project.owner,
            content: project,
            reason: reason
          )
          
          render json: {
            message: 'Project hidden successfully',
            project: moderation_content_json(project)
          }
        end

        # POST /api/v1/admin/moderation/projects/:id/unhide
        def unhide_project
          project = Project.find(params[:id])
          project.unhide!
          
          render json: {
            message: 'Project unhidden successfully',
            project: moderation_content_json(project)
          }
        end

        # POST /api/v1/admin/moderation/comments/:id/hide
        def hide_comment
          comment = Comment.find(params[:id])
          reason = params[:reason] || 'Violated comment policy'
          
          comment.hide!(reason: reason, admin: current_user)
          
          NotificationService.content_hidden(
            user: comment.user,
            content: comment,
            reason: reason
          )
          
          render json: {
            message: 'Comment hidden successfully',
            comment: moderation_content_json(comment)
          }
        end

        # POST /api/v1/admin/moderation/comments/:id/unhide
        def unhide_comment
          comment = Comment.find(params[:id])
          comment.unhide!
          
          render json: {
            message: 'Comment unhidden successfully',
            comment: moderation_content_json(comment)
          }
        end

        # GET /api/v1/admin/moderation/stats
        def stats
          render json: {
            reports: report_stats,
            users: user_moderation_stats,
            content: content_moderation_stats
          }
        end

        private

        def require_admin
          unless current_user&.admin?
            render json: { error: 'Unauthorized: Admin access required' }, status: :forbidden
          end
        end

        def set_report
          @report = Report.find(params[:id])
        end

        def report_update_params
          params.permit(:status)
        end

        def detailed_report_json(report)
          {
            id: report.id,
            reason: report.reason,
            description: report.description,
            status: report.status,
            reportable: report.reportable_details,
            reporter: {
              id: report.reporter.id,
              full_name: report.reporter.full_name,
              email: report.reporter.email,
              is_suspended: report.reporter.is_suspended
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

        def moderation_user_json(user)
          {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            is_suspended: user.is_suspended,
            is_reported: user.is_reported,
            suspended_at: user.suspended_at,
            suspended_reason: user.suspended_reason,
            suspended_by: user.suspended_by ? {
              id: user.suspended_by.id,
              full_name: user.suspended_by.full_name
            } : nil,
            reports_count: user.reports_count
          }
        end

        def moderation_content_json(content)
          base = {
            id: content.id,
            type: content.class.name,
            is_hidden: content.is_hidden,
            is_reported: content.is_reported,
            hidden_at: content.hidden_at,
            hidden_reason: content.hidden_reason,
            hidden_by: content.hidden_by ? {
              id: content.hidden_by.id,
              full_name: content.hidden_by.full_name
            } : nil,
            reports_count: content.reports_count
          }
          
          case content
          when Project
            base.merge(title: content.title, owner: content.owner.full_name)
          when Comment
            base.merge(content: content.content, user: content.user.full_name)
          else
            base
          end
        end

        def report_stats
          {
            total: Report.count,
            pending: Report.where(status: 'pending').count,
            reviewing: Report.where(status: 'reviewing').count,
            resolved: Report.where(status: 'resolved').count,
            dismissed: Report.where(status: 'dismissed').count,
            by_type: {
              users: Report.for_type('User').count,
              projects: Report.for_type('Project').count,
              comments: Report.for_type('Comment').count
            }
          }
        end

        def user_moderation_stats
          {
            total_users: User.count,
            suspended: User.suspended.count,
            reported: User.reported.count,
            active: User.active.count
          }
        end

        def content_moderation_stats
          {
            projects: {
              total: Project.count,
              hidden: Project.hidden.count,
              reported: Project.reported.count,
              visible: Project.visible.count
            },
            comments: {
              total: Comment.count,
              hidden: Comment.hidden.count,
              reported: Comment.reported.count,
              visible: Comment.visible.count
            }
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
end
