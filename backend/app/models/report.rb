class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: 'User', optional: true
  
  validates :reason, presence: true
  validates :status, inclusion: { in: %w[pending reviewing resolved dismissed] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :for_type, ->(type) { where(reportable_type: type) }
  
  def reportable_details
    case reportable_type
    when 'User'
      { type: 'User', name: reportable.full_name, email: reportable.email, id: reportable.id }
    when 'Project'
      { type: 'Project', title: reportable.title, owner: reportable.owner.full_name, id: reportable.id }
    when 'Comment'
      { type: 'Comment', content: reportable.content&.truncate(100), user: reportable.user.full_name, id: reportable.id }
    when 'Tag'
      { type: 'Tag', name: reportable.tag_name, id: reportable.id }
    else
      { type: reportable_type, id: reportable.id }
    end
  rescue
    { type: reportable_type, id: reportable_id, error: 'Not found' }
  end
end
