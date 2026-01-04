module ApiLogging
  extend ActiveSupport::Concern

  included do
    around_action :log_api_request
  end

  private

  def log_api_request
    start_time = Time.current
    
    begin
      yield
      
      # Log successful request
      duration = (Time.current - start_time) * 1000 # Convert to milliseconds
      log_request_to_db(response.status, nil, duration)
      
    rescue StandardError => e
      # Log failed request
      duration = (Time.current - start_time) * 1000
      log_request_to_db(500, e.message, duration)
      raise
    end
  end

  def log_request_to_db(status, error_message, duration)
    # Log synchronously to ensure logs are captured
    ApiLog.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_method: request.method,
      request_path: request.fullpath,
      request_params: filtered_params.to_json,
      response_status: status,
      response_message: error_message || response_message_for_status(status),
      user_id: current_user&.id,
      duration: duration
    )
  rescue StandardError => e
    # Don't let logging errors break the application
    Rails.logger.error "Failed to log API request: #{e.message}"
  end

  def filtered_params
    # Filter sensitive params
    params.to_unsafe_h.except('controller', 'action', 'password', 'password_confirmation', 'token')
  end

  def response_message_for_status(status)
    case status
    when 200..299
      'Success'
    when 400
      'Bad Request'
    when 401
      'Unauthorized'
    when 403
      'Forbidden'
    when 404
      'Not Found'
    when 422
      'Unprocessable Entity'
    when 500..599
      'Server Error'
    else
      'Unknown'
    end
  end
end
