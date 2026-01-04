class Comment < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy
  
  validates :content, presence: true
  
  # Scopes
  scope :visible, -> { where(is_hidden: false) }
  scope :hidden, -> { where(is_hidden: true) }
  scope :reported, -> { where(is_reported: true) }
  
  # Increment project comment count on create
  after_create :increment_project_comments
  after_destroy :decrement_project_comments
  
  # Moderation methods
  def hide!(reason:, admin:)
    update!(
      is_hidden: true,
      is_reported: true,
      hidden_at: Time.current,
      hidden_reason: reason,
      hidden_by_id: admin.id
    )
  end
  
  def unhide!
    update!(
      is_hidden: false,
      hidden_at: nil,
      hidden_reason: nil,
      hidden_by_id: nil
    )
  end
  
  def author
    user&.full_name || 'Anonymous'
  end
  
  def text
    content
  end
  
  def timestamp
    created_at
  end
  
  private
  
  def increment_project_comments
    project.project_stat&.increment!(:total_comments)
  end
  
  def decrement_project_comments
    project.project_stat&.decrement!(:total_comments)
  end
end
