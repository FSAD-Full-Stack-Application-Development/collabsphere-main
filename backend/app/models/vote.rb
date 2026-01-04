class Vote < ApplicationRecord
  belongs_to :project
  belongs_to :user
  
  validates :vote_type, inclusion: { in: %w[up down] }
  validates :user_id, uniqueness: { scope: :project_id, message: "already voted on this project" }
end
