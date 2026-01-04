class FundingRequest < ApplicationRecord
  belongs_to :project
  belongs_to :funder, class_name: 'User'
  belongs_to :verifier, class_name: 'User', foreign_key: 'verified_by', optional: true
  
  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending verified rejected] }
  validates :funder_id, uniqueness: { 
    scope: [:project_id, :status], 
    conditions: -> { where(status: 'pending') },
    message: "already has a pending funding request for this project" 
  }
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :verified, -> { where(status: 'verified') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Status change methods
  def verify!(verifier_user)
    raise ActiveRecord::RecordInvalid.new(self) unless pending?
    
    transaction do
      update!(
        status: 'verified',
        verified_by: verifier_user.id,
        verified_at: Time.current
      )
      
      # Create the actual Fund record
      Fund.create!(
        project: project,
        funder: funder,
        amount: amount,
        funded_at: Time.current
      )
      
      # Update project's current_funding
      project.increment!(:current_funding, amount)
    end
  end
  
  def reject!(verifier_user)
    raise ActiveRecord::RecordInvalid.new(self) unless pending?
    
    update!(
      status: 'rejected',
      verified_by: verifier_user.id,
      verified_at: Time.current
    )
  end
  
  def pending?
    status == 'pending'
  end
  
  def verified?
    status == 'verified'
  end
  
  def rejected?
    status == 'rejected'
  end
end
