class Subscriber < ApplicationRecord
  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }
  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/[\s.\-]/, "") }

  validates :email, presence: { message: "không được để trống" },
                    uniqueness: { message: "đã đăng ký rồi" },
                    format: { with: URI::MailTo::EMAIL_REGEXP,
                              message: "không đúng định dạng",
                              allow_blank: true }
  validates :phone, format: { with: /\A0\d{8,10}\z/,
                              message: "không đúng định dạng (ví dụ 0901234567)",
                              allow_blank: true }

  before_validation :assign_token, on: :create
  before_validation :assign_subscribed_at, on: :create

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(created_at: :desc) }

  # KHÔNG override to_param bằng unsubscribe_token: route admin dùng id,
  # đặt to_param = token sẽ làm admin_subscriber_path sinh ra token và find(id) văng 404.
  def display_name
    name.presence || email.split("@").first
  end

  def unsubscribe!
    update!(active: false, unsubscribed_at: Time.current)
  end

  def resubscribe!
    update!(active: true, unsubscribed_at: nil, subscribed_at: Time.current)
  end

  def record_email_sent!
    update_columns(
      last_emailed_at: Time.current,
      emails_sent_count: emails_sent_count + 1,
      updated_at: Time.current
    )
  end

  private

  def assign_token
    return if unsubscribe_token.present?

    self.unsubscribe_token = loop do
      candidate = SecureRandom.urlsafe_base64(24)
      break candidate unless Subscriber.exists?(unsubscribe_token: candidate)
    end
  end

  def assign_subscribed_at
    self.subscribed_at ||= Time.current
  end
end
