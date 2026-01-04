class Resource < ApplicationRecord
  belongs_to :project
  belongs_to :added_by, class_name: 'User'

  validates :title, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true
  validates :status, inclusion: { in: ['pending', 'approved', 'rejected'] }

  # Automatically approve resources added by project owner
  before_validation :set_default_status, on: :create

  private

  def set_default_status
    return if status.present?

    # Auto-approve if added by project owner
    if added_by_id == project.owner_id
      self.status = 'approved'
    else
      self.status = 'pending'
    end
  end
end
