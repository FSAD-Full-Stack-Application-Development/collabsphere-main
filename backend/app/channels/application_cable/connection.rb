module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.email
    end

    private

    def find_verified_user
      # Extract token from request params or headers
      token = request.params[:token] || extract_token_from_headers
      
      if token.blank?
        reject_unauthorized_connection
      end

      begin
        decoded = JsonWebToken.decode(token)
        user = User.find(decoded[:user_id])
        user
      rescue ActiveRecord::RecordNotFound, JWT::DecodeError => e
        reject_unauthorized_connection
      end
    end

    def extract_token_from_headers
      # Try to get token from Authorization header
      auth_header = request.headers['Authorization']
      return nil unless auth_header
      
      auth_header.split(' ').last if auth_header.start_with?('Bearer ')
    end
  end
end
