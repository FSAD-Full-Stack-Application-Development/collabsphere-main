class CollaborationRequest < ApplicationRecord
  belongs_to :project
  belongs_to :user
  
  # Status enum: pending, approved, rejected
  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected' }, validate: true
  
  validate :unique_pending_request_per_user_project
  
  # Prevent multiple pending requests per user per project
  def unique_pending_request_per_user_project
    if status == 'pending' && project && user
      existing = project.collaboration_requests.where(user_id: user_id, status: 'pending')
      existing = existing.where.not(id: id) if persisted?
      if existing.exists?
        errors.add(:user_id, "has already requested to join this project")
      end
    end
  end
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  
  # Prevent requesting if already a collaborator
  validate :user_not_already_collaborating
  
  scope :pending, -> { where(status: 'pending') }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Approve the request and create collaboration
  def approve!
    ActiveRecord::Base.transaction do
      update!(status: 'approved')
      
      # Create collaboration with member role (default for approved requests)
      Collaboration.create!(
        project_id: project_id,
        user_id: user_id,
        project_role: :member
      )
    end
  end
  
  # Reject the request
  def reject!
    destroy!
  end
  
  private
  
  def user_not_already_collaborating
    if project && user && project.collaborations.exists?(user_id: user_id)
      errors.add(:user_id, "is already a collaborator on this project")
    end
  end
end
