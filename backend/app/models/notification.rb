class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :notifiable, polymorphic: true
  
  # Notification types
  TYPES = {
    # Collaboration
    collaboration_request: 'collaboration_request',
    collaboration_approved: 'collaboration_approved',
    collaboration_rejected: 'collaboration_rejected',
    
    # Funding
    funding_request: 'funding_request',
    funding_verified: 'funding_verified',
    funding_rejected: 'funding_rejected',
    
    # Project
    project_comment: 'project_comment',
    project_vote: 'project_vote',
    project_milestone: 'project_milestone',
    
    # Comments
    comment_reply: 'comment_reply',
    comment_liked: 'comment_liked',
    
    # Messages
    new_message: 'new_message',
    
    # Resources
    resource_added: 'resource_added',
    
    # Reports
    project_reported: 'project_reported',
    user_reported: 'user_reported',
    
    # Moderation
    content_reported: 'content_reported',
    user_suspended: 'user_suspended',
    user_unsuspended: 'user_unsuspended',
    content_hidden: 'content_hidden'
  }.freeze
  
  validates :notification_type, presence: true, inclusion: { in: TYPES.values }
  validates :message, presence: true
  validates :user_id, presence: true
  
  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_type, ->(type) { where(notification_type: type) }
  
  # Mark as read
  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
  
  # Mark as unread
  def mark_as_unread!
    update!(read: false, read_at: nil)
  end
  
  # Class method to create notification
  def self.create_for(user:, type:, notifiable:, actor: nil, message:, metadata: {})
    create!(
      user: user,
      notification_type: type,
      notifiable: notifiable,
      actor: actor,
      message: message,
      metadata: metadata
    )
  end
  
  # Class method to mark all as read for a user
  def self.mark_all_read_for_user(user)
    where(user: user, read: false).update_all(read: true, read_at: Time.current)
  end
end
