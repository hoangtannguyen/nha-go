class AdminUser < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "không đúng định dạng", allow_blank: true }
  validates :name, presence: true
  validates :password, length: { minimum: 8, message: "phải từ 8 ký tự trở lên" }, allow_nil: true

  scope :enabled, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def self.authenticate(email, password)
    enabled.find_by(email: email.to_s.strip.downcase)&.authenticate(password)
  end

  def touch_login!
    update_column(:last_login_at, Time.current)
  end
end
