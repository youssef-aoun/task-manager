class User < ApplicationRecord
  has_secure_password
  has_many :projects, foreign_key: "user_id", dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :joined_projects, through: :project_memberships, source: :project
  has_many :tasks, dependent: :nullify

  validates :name, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :gender, inclusion: { in: %w(male female) }, allow_nil: true
end
