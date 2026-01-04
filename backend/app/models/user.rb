class User < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy
  has_many :collaborations, dependent: :destroy
  has_many :collaborated_projects, through: :collaborations, source: :project
  has_many :funding_requests, foreign_key: 'funder_id', dependent: :destroy
  has_many :funds, foreign_key: 'funder_id', dependent: :destroy
  has_many :funded_projects, through: :funds, source: :project
  has_many :resources, foreign_key: 'added_by_id', dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', foreign_key: 'receiver_id', dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  has_many :reports_made, class_name: 'Report', foreign_key: 'reporter_id', dependent: :destroy
  has_many :reports_received, as: :reportable, class_name: 'Report', dependent: :destroy
  
  # Validations
  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :system_role, inclusion: { in: %w[admin user], message: "%{value} is not a valid role" }, allow_nil: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :age, numericality: { only_integer: true, greater_than: 0, less_than: 150 }, allow_nil: true
  validates :occupation, length: { maximum: 150 }, allow_nil: true
  validates :computer_equipment, length: { maximum: 255 }, allow_nil: true
  validates :connection_type, length: { maximum: 100 }, allow_nil: true

  # Set default system_role to 'user' if not provided
  before_validation :set_default_system_role, on: :create
  
  # Scopes
  scope :by_country, ->(country) { where(country: country) }
  scope :by_university, ->(university) { where(university: university) }
  scope :with_tags, -> { includes(:tags) }
  scope :suspended, -> { where(is_suspended: true) }
  scope :active, -> { where(is_suspended: false) }
  scope :reported, -> { where(is_reported: true) }
  
  def reports_count
    reports_received.count
  end

  def collaborations_count
    collaborations.count
  end
  
  # Moderation methods
  def suspend!(reason:, admin:)
    update!(
      is_suspended: true,
      is_reported: true,
      suspended_at: Time.current,
      suspended_reason: reason,
      suspended_by_id: admin.id
    )
  end
  
  def unsuspend!
    update!(
      is_suspended: false,
      suspended_at: nil,
      suspended_reason: nil,
      suspended_by_id: nil
    )
  end
  
  def suspended_by
    User.find_by(id: suspended_by_id) if suspended_by_id
  end
  
  # Role helper methods
  def admin?
    system_role == 'admin'
  end
  
  def member?
    system_role == 'user'
  end
  
  def visitor?
    system_role.nil? || system_role == 'visitor'
  end
  
  def suspended?
    is_suspended == true
  end
  
  private
  
  def set_default_system_role
    self.system_role ||= 'user'
  end
end
