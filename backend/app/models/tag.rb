class Tag < ApplicationRecord
  has_many :project_tags, dependent: :destroy
  has_many :projects, through: :project_tags
  has_many :user_tags, dependent: :destroy
  has_many :users, through: :user_tags
  has_many :reports, as: :reportable, dependent: :destroy
  
  validates :tag_name, presence: true, uniqueness: true, length: { maximum: 50 }
end
