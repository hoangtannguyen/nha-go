class NotifyCustomerOfShipmentJob < ApplicationJob
  queue_as :default

  # Báo khách đơn đã được gửi đi kèm mã vận đơn. Mỗi đơn chỉ gửi một lần:
  # đánh dấu shipping_notified_at bằng một câu UPDATE có điều kiện trước khi gửi,
  # nên job chạy trùng (admin lưu nhiều lần, job retry) cũng không gửi lặp.
  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.nil? || order.email.blank? || !order.shipped? || !order.shipment?

    claimed = Order.where(id: order.id, shipping_notified_at: nil)
                   .update_all(shipping_notified_at: Time.current)
    return if claimed.zero?

    begin
      OrderMailer.shipment_sent(order).deliver_now
    rescue StandardError
      # Chưa gửi được thì trả lại cờ để lần retry sau còn gửi
      Order.where(id: order.id).update_all(shipping_notified_at: nil)
      raise
    end
  end
end
