class AuditLog < ApplicationRecord
  belongs_to :user
  
  validates :action, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  
  # Helper to create audit log
  def self.log(user:, action:, resource_type: nil, resource_id: nil, details: nil, ip_address: nil)
    create(
      user: user,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      details: details,
      ip_address: ip_address
    )
  end
end
