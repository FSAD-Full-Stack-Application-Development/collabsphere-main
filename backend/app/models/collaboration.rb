class Collaboration < ApplicationRecord
  belongs_to :project
  belongs_to :user
  
  # Simple 3-role structure: owner, member, viewer
  enum :project_role, { owner: 0, member: 1, viewer: 2 }
  
  validates :project_role, presence: true
  validates :user_id, uniqueness: { scope: :project_id, message: "already collaborating on this project" }
  
  after_destroy :cleanup_collaboration_requests
  
  private
  
  def cleanup_collaboration_requests
    # Remove any collaboration requests for this user-project pair
    # so they can request to join again if they want
    project.collaboration_requests.where(user_id: user_id).destroy_all
  end
end
