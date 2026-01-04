# Rate limiting and spam protection configuration
# Note: Requires 'rack-attack' gem to be installed

return unless defined?(Rack::Attack)

class Rack::Attack
  # Helper method to extract user from JWT token
  def self.user_from_token(req)
    return nil unless req.env['HTTP_AUTHORIZATION'].present?
    
    token = req.env['HTTP_AUTHORIZATION'].split(' ').last
    begin
      decoded = JsonWebToken.decode(token)
      { id: decoded[:user_id], role: decoded[:role] }
    rescue
      nil
    end
  end
  
  # PRIMARY: Token-based rate limiting for authenticated users
  throttle('authenticated/regular_user', limit: 100, period: 60) do |req|
    next if req.path.start_with?('/assets')
    
    user = user_from_token(req)
    if user && user[:role] != 'admin'
      "user:#{user[:id]}"
    end
  end
  
  # Higher limits for admin users
  throttle('authenticated/admin', limit: 500, period: 60) do |req|
    next if req.path.start_with?('/assets')
    
    user = user_from_token(req)
    if user && user[:role] == 'admin'
      "admin:#{user[:id]}"
    end
  end
  
  # Specific action limits for authenticated users
  throttle('user/reports', limit: 10, period: 3600) do |req|
    if req.path == '/api/v1/reports' && req.post?
      user = user_from_token(req)
      "user:#{user[:id]}:reports" if user
    end
  end
  
  throttle('user/comments', limit: 30, period: 60) do |req|
    if req.path.match?(/\/api\/v1\/comments/) && req.post?
      user = user_from_token(req)
      "user:#{user[:id]}:comments" if user
    end
  end
  
  throttle('user/messages', limit: 60, period: 60) do |req|
    if req.path.match?(/\/api\/v1\/messages/) && req.post?
      user = user_from_token(req)
      "user:#{user[:id]}:messages" if user
    end
  end
  
  # FALLBACK: IP-based rate limiting for public/unauthenticated endpoints only
  throttle('public/login', limit: 5, period: 60) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      # Rate limit by email to prevent credential stuffing
      req.params['email']&.to_s&.downcase&.strip || req.ip
    end
  end

  throttle('public/register', limit: 3, period: 300) do |req|
    if req.path == '/api/v1/auth/register' && req.post?
      req.ip
    end
  end
  
  # IP-based limit for unauthenticated requests (very permissive)
  throttle('public/ip', limit: 20, period: 60) do |req|
    next if req.path.start_with?('/assets')
    next if req.env['HTTP_AUTHORIZATION'].present? # Skip if authenticated
    
    # Only apply to unauthenticated public endpoints
    public_paths = ['/api/v1/auth/login', '/api/v1/auth/register', '/api/v1/projects']
    if public_paths.any? { |path| req.path.start_with?(path) }
      req.ip
    end
  end

  # Block requests from known spam IPs
  blocklist('block spam IPs') do |req|
    # Check if IP is in our spam list (stored in Redis or database)
    SpamFilter.blocked_ip?(req.ip)
  end
  
  # Block suspended users from making requests
  blocklist('block suspended users') do |req|
    user = user_from_token(req)
    if user
      begin
        User.find(user[:id]).is_suspended
      rescue
        false
      end
    end
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    match_data = env['rack.attack.match_data'] || {}
    retry_after = match_data[:period]
    throttle_name = env['rack.attack.matched']
    
    # Provide helpful error messages based on throttle type
    message = if throttle_name.to_s.include?('authenticated')
                'Rate limit exceeded for your account. Please slow down.'
              elsif throttle_name.to_s.include?('login')
                'Too many login attempts. Please try again later.'
              elsif throttle_name.to_s.include?('register')
                'Too many registration attempts. Please try again later.'
              else
                'Rate limit exceeded. Please try again later.'
              end
    
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s,
        'X-RateLimit-Limit' => match_data[:limit].to_s,
        'X-RateLimit-Period' => retry_after.to_s
      },
      [{
        error: message,
        retry_after: retry_after,
        throttle: throttle_name
      }.to_json]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_response = lambda do |env|
    reason = if env['rack.attack.matched'] == 'block suspended users'
               'Your account has been suspended. Contact support for assistance.'
             else
               'Access denied due to suspicious activity.'
             end
    
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{
        error: reason,
        blocked: true
      }.to_json]
    ]
  end
end

# Enable rack-attack
Rails.application.config.middleware.use Rack::Attack
