class NotificationService
  class << self
    # Collaboration Request Notifications
    def collaboration_requested(collaboration_request)
      Notification.create_for(
        user: collaboration_request.project.owner,
        type: Notification::TYPES[:collaboration_request],
        notifiable: collaboration_request,
        actor: collaboration_request.user,
        message: "#{collaboration_request.user.full_name} requested to collaborate on #{collaboration_request.project.title}",
        metadata: {
          project_id: collaboration_request.project_id,
          project_title: collaboration_request.project.title,
          user_id: collaboration_request.user_id,
          user_name: collaboration_request.user.full_name
        }
      )
    end
    
    def collaboration_approved(collaboration_request)
      Notification.create_for(
        user: collaboration_request.user,
        type: Notification::TYPES[:collaboration_approved],
        notifiable: collaboration_request,
        actor: collaboration_request.project.owner,
        message: "Your collaboration request for #{collaboration_request.project.title} was approved",
        metadata: {
          project_id: collaboration_request.project_id,
          project_title: collaboration_request.project.title,
          approved_by: collaboration_request.project.owner.full_name
        }
      )
    end
    
    def collaboration_rejected(collaboration_request)
      Notification.create_for(
        user: collaboration_request.user,
        type: Notification::TYPES[:collaboration_rejected],
        notifiable: collaboration_request,
        actor: collaboration_request.project.owner,
        message: "Your collaboration request for #{collaboration_request.project.title} was rejected",
        metadata: {
          project_id: collaboration_request.project_id,
          project_title: collaboration_request.project.title,
          rejected_by: collaboration_request.project.owner.full_name
        }
      )
    end
    
    # Funding Request Notifications
    def funding_requested(funding_request)
      Notification.create_for(
        user: funding_request.project.owner,
        type: Notification::TYPES[:funding_request],
        notifiable: funding_request,
        actor: funding_request.funder,
        message: "#{funding_request.funder.full_name} offered $#{funding_request.amount} funding for #{funding_request.project.title}",
        metadata: {
          project_id: funding_request.project_id,
          project_title: funding_request.project.title,
          funder_id: funding_request.funder_id,
          funder_name: funding_request.funder.full_name,
          amount: funding_request.amount
        }
      )
    end
    
    def funding_verified(funding_request)
      Notification.create_for(
        user: funding_request.funder,
        type: Notification::TYPES[:funding_verified],
        notifiable: funding_request,
        actor: funding_request.verifier,
        message: "Your funding offer of $#{funding_request.amount} for #{funding_request.project.title} was accepted",
        metadata: {
          project_id: funding_request.project_id,
          project_title: funding_request.project.title,
          amount: funding_request.amount,
          verified_by: funding_request.verifier.full_name
        }
      )
    end
    
    def funding_rejected(funding_request)
      Notification.create_for(
        user: funding_request.funder,
        type: Notification::TYPES[:funding_rejected],
        notifiable: funding_request,
        actor: funding_request.verifier,
        message: "Your funding offer of $#{funding_request.amount} for #{funding_request.project.title} was declined",
        metadata: {
          project_id: funding_request.project_id,
          project_title: funding_request.project.title,
          amount: funding_request.amount,
          rejected_by: funding_request.verifier.full_name
        }
      )
    end
    
    # Comment Notifications
    def project_commented(comment)
      return unless comment.user.present? && comment.project.present?
      
      # Notify project owner (only for top-level comments)
      if comment.parent_id.nil? && comment.user_id != comment.project.owner_id && comment.project.owner.present?
        Notification.create_for(
          user: comment.project.owner,
          type: Notification::TYPES[:project_comment],
          notifiable: comment,
          actor: comment.user,
          message: "#{comment.user.full_name} commented on #{comment.project.title}",
          metadata: {
            project_id: comment.project_id,
            project_title: comment.project.title,
            comment_preview: comment.content&.truncate(100)
          }
        )
      end
      
      # Notify parent comment author if this is a reply
      if comment.parent_id.present?
        parent_comment = comment.parent
        if parent_comment.present? && parent_comment.user.present? && comment.user_id != parent_comment.user_id
          Notification.create_for(
            user: parent_comment.user,
            type: Notification::TYPES[:comment_reply],
            notifiable: comment,
            actor: comment.user,
            message: "#{comment.user.full_name} replied to your comment on #{comment.project.title}",
            metadata: {
              project_id: comment.project_id,
              project_title: comment.project.title,
              parent_comment_id: parent_comment.id,
              comment_preview: comment.content&.truncate(100)
            }
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error "Failed to create project_commented notification: #{e.message}"
    end
    
    # Comment Like Notification
    def comment_liked(comment, liker)
      # Notify comment author when someone likes their comment
      return unless comment.user_id != liker.id
      return unless comment.user.present? && comment.project.present?
      
      Notification.create_for(
        user: comment.user,
        type: Notification::TYPES[:comment_liked],
        notifiable: comment,
        actor: liker,
        message: "#{liker.full_name} liked your comment on #{comment.project.title}",
        metadata: {
          project_id: comment.project_id,
          project_title: comment.project.title,
          comment_preview: comment.content&.truncate(100)
        }
      )
    rescue StandardError => e
      Rails.logger.error "Failed to create comment_liked notification: #{e.message}"
    end
    
    # Vote Notifications
    def project_voted(vote)
      return unless vote.user.present? && vote.project.present? && vote.project.owner.present?
      
      # Notify project owner of upvotes only
      if vote.vote_type == 'up' && vote.user_id != vote.project.owner_id
        Notification.create_for(
          user: vote.project.owner,
          type: Notification::TYPES[:project_vote],
          notifiable: vote,
          actor: vote.user,
          message: "#{vote.user.full_name} upvoted #{vote.project.title}",
          metadata: {
            project_id: vote.project_id,
            project_title: vote.project.title,
            vote_type: vote.vote_type
          }
        )
      end
    rescue StandardError => e
      Rails.logger.error "Failed to create project_voted notification: #{e.message}"
    end
    
    # Message Notifications
    def message_received(message)
      Notification.create_for(
        user: message.receiver,
        type: Notification::TYPES[:new_message],
        notifiable: message,
        actor: message.sender,
        message: "#{message.sender.full_name} sent you a message",
        metadata: {
          sender_id: message.sender_id,
          sender_name: message.sender.full_name,
          message_preview: message.content&.truncate(100)
        }
      )
    end
    
    # Resource Notifications
    def resource_added(resource)
      # Notify all collaborators when a resource is added
      project = resource.project
      recipients = [project.owner] + project.collaborators
      recipients.uniq.each do |user|
        next if user.id == resource.added_by_id # Don't notify the person who added it
        
        Notification.create_for(
          user: user,
          type: Notification::TYPES[:resource_added],
          notifiable: resource,
          actor: resource.added_by,
          message: "#{resource.added_by.full_name} added a resource to #{project.title}",
          metadata: {
            project_id: project.id,
            project_title: project.title,
            resource_title: resource.title,
            resource_url: resource.url
          }
        )
      end
    end
    
    # Report Notifications
    def project_reported(report)
      # Notify project owner
      if report.reportable_type == 'Project'
        Notification.create_for(
          user: report.reportable.owner,
          type: Notification::TYPES[:project_reported],
          notifiable: report,
          actor: report.reporter,
          message: "Your project #{report.reportable.title} was reported",
          metadata: {
            project_id: report.reportable_id,
            project_title: report.reportable.title,
            reason: report.reason
          }
        )
      end
    end
    
    def user_reported(report)
      # Notify reported user
      if report.reportable_type == 'User'
        Notification.create_for(
          user: report.reportable,
          type: Notification::TYPES[:user_reported],
          notifiable: report,
          actor: report.reporter,
          message: "Your account was reported",
          metadata: {
            reason: report.reason
          }
        )
      end
    end
    
    # Moderation Notifications
    def content_reported(user:, report:)
      Notification.create_for(
        user: user,
        type: Notification::TYPES[:content_reported],
        notifiable: report,
        actor: report.reporter,
        message: "New content report: #{report.reportable_type} - #{report.reason}",
        metadata: {
          report_id: report.id,
          reportable_type: report.reportable_type,
          reportable_id: report.reportable_id,
          reason: report.reason
        }
      )
    end
    
    def user_suspended(user:, admin:, reason:)
      Notification.create_for(
        user: user,
        type: Notification::TYPES[:user_suspended],
        notifiable: user,
        actor: admin,
        message: "Your account has been suspended: #{reason}",
        metadata: {
          reason: reason,
          suspended_by: admin.full_name
        }
      )
    end
    
    def user_unsuspended(user:, admin:)
      Notification.create_for(
        user: user,
        type: Notification::TYPES[:user_unsuspended],
        notifiable: user,
        actor: admin,
        message: "Your account has been restored",
        metadata: {
          unsuspended_by: admin.full_name
        }
      )
    end
    
    def content_hidden(user:, content:, reason:)
      Notification.create_for(
        user: user,
        type: Notification::TYPES[:content_hidden],
        notifiable: content,
        actor: nil,
        message: "Your #{content.class.name.downcase} has been hidden: #{reason}",
        metadata: {
          content_type: content.class.name,
          content_id: content.id,
          reason: reason
        }
      )
    end
  end
end
