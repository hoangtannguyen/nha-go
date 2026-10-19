class Customer < ApplicationRecord
  has_many :orders, dependent: :nullify

  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/[\s.\-]/, "") }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :phone, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  # Gắn đơn vào khách có sẵn theo số điện thoại, chưa có thì tạo mới
  def self.for_order(order)
    customer = find_or_initialize_by(phone: order.phone)
    customer.name = order.customer_name
    customer.address = order.address
    customer.save!
    customer
  end

  def orders_count
    orders.size
  end

  def total_spent
    orders.sum(:total)
  end

  def last_ordered_at
    orders.maximum(:created_at)
  end
end
