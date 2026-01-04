class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :collaborations, dependent: :destroy
  has_many :collaborators, through: :collaborations, source: :user
  has_many :collaboration_requests, dependent: :destroy
  has_many :funding_requests, dependent: :destroy
  has_many :funds, dependent: :destroy
  has_many :funders, through: :funds
  has_many :project_tags, dependent: :destroy
  has_many :tags, through: :project_tags
  has_many :resources, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :messages, dependent: :nullify
  has_one :project_stat, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy
  
  # Validations
  validates :title, presence: true, length: { maximum: 150 }
  validates :status, inclusion: { in: %w[Ideation Ongoing Completed] }
  validates :visibility, inclusion: { in: %w[public private restricted] }
  
  # Scopes
  scope :visible, -> { where(is_hidden: false) }
  scope :hidden, -> { where(is_hidden: true) }
  scope :reported, -> { where(is_reported: true) }
  
  # Callbacks
  after_create :create_project_stat
  
  # Instance methods
  def vote_count
    votes.where(vote_type: 'up').count - votes.where(vote_type: 'down').count
  end
  
  def reports_count
    reports.count
  end
  
  def total_funding
    funds.sum(:amount)
  end
  
  def funders_count
    funds.count
  end
  
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
  
  def hidden_by
    User.find_by(id: hidden_by_id) if hidden_by_id
  end
  
  private
  
  def create_project_stat
    ProjectStat.create(project: self, total_views: 0, total_votes: 0, total_comments: 0)
  end
end
