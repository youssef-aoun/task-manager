class Task < ApplicationRecord
  validates :title, presence: true, length: { minimum: 6, maximum: 100 }
  validates :status, presence: true, length: { maximum: 20 }
  belongs_to :user

  scope :by_status, -> (status){ where(status: status) }
  scope :with_user, -> {includes(:user)}
end
