class ApiLog < ApplicationRecord
  belongs_to :user, optional: true

  # Scopes for filtering
  scope :successful, -> { where('response_status >= 200 AND response_status < 300') }
  scope :failed, -> { where('response_status >= 400') }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', Time.current.beginning_of_week) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  scope :by_ip, ->(ip) { where(ip_address: ip) }
  scope :by_method, ->(method) { where(request_method: method) }
  scope :by_path, ->(path) { where('request_path LIKE ?', "%#{path}%") }

  # Statistics methods
  def self.stats_for_period(start_time, end_time = Time.current)
    logs = where(created_at: start_time..end_time)
    {
      total_requests: logs.count,
      successful_requests: logs.successful.count,
      failed_requests: logs.failed.count,
      success_rate: calculate_success_rate(logs),
      avg_duration: logs.average(:duration)&.round(3) || 0,
      requests_by_method: logs.group(:request_method).count,
      requests_by_status: logs.group(:response_status).count,
      top_endpoints: logs.group(:request_path).count.sort_by { |_, v| -v }.first(10).to_h,
      top_ips: logs.group(:ip_address).count.sort_by { |_, v| -v }.first(10).to_h
    }
  end

  def self.calculate_success_rate(logs)
    total = logs.count
    return 0 if total.zero?
    
    successful = logs.successful.count
    ((successful.to_f / total) * 100).round(2)
  end

  def self.daily_stats
    stats_for_period(Time.current.beginning_of_day)
  end

  def self.weekly_stats
    stats_for_period(Time.current.beginning_of_week)
  end

  def self.monthly_stats
    stats_for_period(Time.current.beginning_of_month)
  end

  def success?
    response_status >= 200 && response_status < 300
  end

  def failed?
    response_status >= 400
  end
end
