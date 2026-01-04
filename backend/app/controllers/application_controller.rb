class ApplicationController < ActionController::API
  include Authenticable
  include ApiLogging
  
  skip_before_action :authorize_request, only: []
  
  # Catch all exceptions and return JSON instead of HTML
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from NoMethodError, with: :handle_no_method_error

  private

  def handle_standard_error(exception)
    Rails.logger.error "Error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.first(10).join("\n")
    
    render json: { 
      error: exception.message,
      type: exception.class.name
    }, status: :internal_server_error
  end

  def handle_no_method_error(exception)
    Rails.logger.error "NoMethodError: #{exception.message}"
    Rails.logger.error exception.backtrace.first(5).join("\n")
    
    render json: { 
      error: exception.message,
      type: 'NoMethodError',
      hint: 'Check if the object/variable exists before calling methods on it'
    }, status: :internal_server_error
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def record_invalid(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end
