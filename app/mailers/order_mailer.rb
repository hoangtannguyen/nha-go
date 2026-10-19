class OrderMailer < ApplicationMailer
  def new_order(order, admin_user)
    @order = order
    @admin_user = admin_user
    @order_items = order.order_items.includes(:product)
    @admin_url = admin_order_url(@order)

    mail to: admin_user.email,
         subject: "[Đơn mới] #{order.code} — #{order.customer_name} — #{price_vnd(order.total)}"
  end

  # Gửi khách khi đơn đã có vận đơn và chuyển sang "Đang giao"
  def shipment_sent(order)
    @order = order
    @order_items = order.order_items.includes(:product)
    @order_url = order_url(@order)
    @lookup_url = Ghtk::LOOKUP_URL
    @freeship = Ghtk::Config.new.freeship?

    mail to: order.email,
         subject: "Đơn #{order.code} đã được gửi đi — mã vận đơn #{order.tracking_code}"
  end

  private

  def price_vnd(amount)
    "#{ActiveSupport::NumberHelper.number_to_delimited(amount, delimiter: '.')}đ"
  end
end
