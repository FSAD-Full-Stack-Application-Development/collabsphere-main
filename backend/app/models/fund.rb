class Fund < ApplicationRecord
  belongs_to :project
  belongs_to :funder, class_name: 'User'
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
end
