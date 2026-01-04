module Auditable
  extend ActiveSupport::Concern

  private

  def log_audit(action:, resource_type: nil, resource_id: nil, details: nil)
    AuditLog.log(
      user: current_user,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      details: details,
      ip_address: request.remote_ip
    )
  rescue => e
    Rails.logger.error "Failed to create audit log: #{e.message}"
  end
end
