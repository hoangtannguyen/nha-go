class NotifyAdminsOfOrderJob < ApplicationJob
  queue_as :default

  # Báo đơn mới cho mọi tài khoản admin đang hoạt động.
  # Một người lỗi không chặn những người còn lại, và không ảnh hưởng tới đơn đã đặt.
  def perform(order_id)
    order = Order.includes(order_items: :product).find_by(id: order_id)
    return if order.nil?

    AdminUser.enabled.find_each do |admin_user|
      OrderMailer.new_order(order, admin_user).deliver_now
    rescue StandardError => e
      Rails.logger.error "[NotifyAdminsOfOrder] Lỗi gửi đơn #{order.code} cho #{admin_user.email}: #{e.message}"
    end
  end
end
