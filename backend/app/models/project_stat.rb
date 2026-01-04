class ProjectStat < ApplicationRecord
  belongs_to :project
  
  validates :project_id, uniqueness: true
end
