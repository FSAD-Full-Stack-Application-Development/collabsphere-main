class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :project, optional: true
  
  validates :content, presence: true
  
  scope :unread, -> { where(is_read: false) }
  scope :for_user, ->(user) { where(receiver_id: user.id) }
end
