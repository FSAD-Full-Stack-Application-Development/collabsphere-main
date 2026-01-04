class SpamFilter
  # Spam keywords and patterns
  SPAM_KEYWORDS = %w[
    viagra cialis pharmacy casino lottery winner prize
    congratulations click-here free-money earn-money
    work-from-home investment-opportunity guaranteed-income
    discount-offer limited-time exclusive-deal
    bitcoin crypto invest double-your-money
    weight-loss miracle-cure enlargement
  ].freeze

  SPAM_PATTERNS = [
    /\b(earn|make)\s+\$?\d+k?\s+(per|a)\s+(day|week|month)\b/i,
    /\b(click|visit)\s+(here|now|this)\s+(link|url)\b/i,
    /\b(www\.|https?:\/\/)[^\s]{30,}\b/i, # Long URLs
    /\b[A-Z]{10,}\b/, # All caps words (10+ chars)
    /(.)\1{5,}/, # Repeated characters
    /\$\$\$+/, # Multiple dollar signs
  ].freeze

  BLOCKED_IPS = [].freeze # Can be populated from database or Redis

  class << self
    # Check if content contains spam
    def spam?(content)
      return false if content.blank?
      
      text = content.to_s.downcase
      
      # Check for spam keywords
      return true if SPAM_KEYWORDS.any? { |keyword| text.include?(keyword) }
      
      # Check for spam patterns
      return true if SPAM_PATTERNS.any? { |pattern| content.to_s.match?(pattern) }
      
      # Check for excessive links
      return true if excessive_links?(content)
      
      # Check for repeated content
      return true if repeated_content?(content)
      
      false
    end

    # Check if IP is blocked
    def blocked_ip?(ip)
      return false if ip.blank?
      BLOCKED_IPS.include?(ip)
    end

    # Analyze content and return spam score (0-100)
    def spam_score(content)
      return 0 if content.blank?
      
      score = 0
      text = content.to_s.downcase
      
      # Keyword matches (10 points each)
      score += SPAM_KEYWORDS.count { |keyword| text.include?(keyword) } * 10
      
      # Pattern matches (15 points each)
      score += SPAM_PATTERNS.count { |pattern| content.to_s.match?(pattern) } * 15
      
      # Excessive links (20 points)
      score += 20 if excessive_links?(content)
      
      # Repeated content (25 points)
      score += 25 if repeated_content?(content)
      
      # Cap at 100
      [score, 100].min
    end

    # Filter spam from content (returns cleaned content or nil if too spammy)
    def filter(content)
      return nil if content.blank?
      
      score = spam_score(content)
      
      # If score is too high, reject entirely
      return nil if score >= 70
      
      # If moderate score, clean the content
      if score >= 30
        cleaned = content.dup
        
        # Remove spam keywords
        SPAM_KEYWORDS.each do |keyword|
          cleaned.gsub!(/\b#{Regexp.escape(keyword)}\b/i, '[removed]')
        end
        
        return cleaned
      end
      
      # Low score, return as is
      content
    end

    # Check if user has been flagged for spam
    def user_spam_flagged?(user)
      return false unless user
      
      # Check if user has high report rate
      recent_reports = user.reports_received.where('created_at > ?', 7.days.ago).count
      return true if recent_reports >= 3
      
      # Check if user has been suspended for spam
      return true if user.is_suspended && user.suspended_reason&.include?('spam')
      
      false
    end

    # Auto-moderate content based on spam score
    def auto_moderate(content_object, content_text)
      score = spam_score(content_text)
      
      if score >= 80
        # High spam score: auto-hide and report
        if content_object.respond_to?(:is_hidden)
          content_object.update(
            is_hidden: true,
            is_reported: true,
            hidden_reason: "Auto-hidden: High spam score (#{score})"
          )
        end
        
        # Create auto-report
        create_spam_report(content_object, score)
        
        return { action: 'hidden', score: score }
      elsif score >= 50
        # Moderate spam score: flag for review
        if content_object.respond_to?(:is_reported)
          content_object.update(is_reported: true)
        end
        
        create_spam_report(content_object, score)
        
        return { action: 'reported', score: score }
      end
      
      { action: 'approved', score: score }
    end

    private

    def excessive_links?(content)
      # Count URLs in content
      url_count = content.to_s.scan(/https?:\/\/[^\s]+/).length
      url_count > 3
    end

    def repeated_content?(content)
      # Check for repeated words or phrases
      words = content.to_s.split
      return false if words.length < 10
      
      # Check if same word appears more than 30% of the time
      word_frequencies = words.group_by(&:downcase).transform_values(&:count)
      max_frequency = word_frequencies.values.max.to_f
      
      (max_frequency / words.length) > 0.3
    end

    def create_spam_report(content_object, score)
      return unless content_object.class.reflect_on_association(:reports)
      
      # Find or create system reporter
      system_user = User.find_or_create_by(email: 'system@collabsphere.com') do |u|
        u.full_name = 'System'
        u.password = SecureRandom.hex(32)
        u.system_role = 'admin'
      end
      
      content_object.reports.create(
        reporter: system_user,
        reason: 'spam',
        description: "Auto-detected spam with score: #{score}",
        status: 'pending'
      )
    rescue => e
      Rails.logger.error("Failed to create spam report: #{e.message}")
    end
  end
end
