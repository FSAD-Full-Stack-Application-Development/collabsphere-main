class ApiLogJob < ApplicationJob
  queue_as :default

  def perform(log_data)
    ApiLog.create!(log_data)
  rescue StandardError => e
    Rails.logger.error "ApiLogJob failed: #{e.message}"
  end
end
