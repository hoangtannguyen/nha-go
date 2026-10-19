class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :order_items, dependent: :destroy

  enum :status, {
    pending: 0,
    confirmed: 1,
    shipped: 2,
    cancelled: 3
  }

  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/[\s.\-]/, "") }
  normalizes :customer_name, with: ->(name) { name.to_s.strip }
  normalizes :street, with: ->(street) { street.to_s.strip }
  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :code, presence: true, uniqueness: true
  validates :customer_name, presence: { message: "không được để trống" }
  validates :phone, presence: { message: "không được để trống" },
                    format: { with: /\A0\d{8,10}\z/, message: "không đúng định dạng (ví dụ 0901234567)", allow_blank: true }
  validates :street, presence: { message: "không được để trống" }
  validates :province_code, presence: { message: "vui lòng chọn tỉnh/thành" }
  validates :ward_code, presence: { message: "vui lòng chọn phường/xã" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "không đúng định dạng", allow_blank: true }
  validates :total, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :must_have_items
  validate :province_must_exist
  validate :ward_must_belong_to_province

  before_validation :assign_code, on: :create
  before_validation :resolve_address_names
  before_validation :compose_address
  before_create :link_customer

  # `address` là địa chỉ đầy đủ đã ghép, dùng cho hiển thị và email.
  # Đơn cũ (trước khi tách trường) chỉ có cột này nên vẫn đọc bình thường.
  validates :address, presence: { message: "không được để trống" }

  scope :recent, -> { order(created_at: :desc) }

  def to_param
    code
  end

  def recalculate_total
    self.total = order_items.sum { |item| item.subtotal }
  end

  # Đơn cũ không có phần tách nhỏ
  def address_parts?
    province_name.present? && ward_name.present?
  end

  def shipment?
    tracking_code.present?
  end

  def carrier_name
    Ghtk::CARRIER_NAME if carrier == Ghtk::CARRIER
  end

  def carrier_status_label
    Ghtk::Status.label(carrier_status_id)
  end

  private

  def must_have_items
    errors.add(:base, "Giỏ hàng đang trống") if order_items.empty?
  end

  def province_must_exist
    return if province_code.blank?

    errors.add(:province_code, "không hợp lệ") unless VietnamAddress.province_code?(province_code)
  end

  def ward_must_belong_to_province
    return if province_code.blank? || ward_code.blank?
    return unless VietnamAddress.province_code?(province_code)

    unless VietnamAddress.ward_code?(province_code, ward_code)
      errors.add(:ward_code, "không thuộc tỉnh/thành đã chọn")
    end
  end

  def resolve_address_names
    self.province_name = VietnamAddress.province_name(province_code) if province_code.present?
    self.ward_name = VietnamAddress.ward_name(province_code, ward_code) if province_code.present? && ward_code.present?
  end

  def compose_address
    parts = [ street, ward_name, province_name ].map { |part| part.to_s.strip }.reject(&:blank?)
    return if parts.empty?

    self.address = parts.join(", ")
  end

  def link_customer
    self.customer ||= Customer.for_order(self)
  end

  def assign_code
    return if code.present?

    self.code = loop do
      candidate = "NG-#{Time.current.strftime('%y%m%d')}-#{SecureRandom.alphanumeric(4).upcase}"
      break candidate unless Order.exists?(code: candidate)
    end
  end
end
