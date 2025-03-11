class User < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_secure_password

  validates :name, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :gender, inclusion: { in: %w(male female) }
end
