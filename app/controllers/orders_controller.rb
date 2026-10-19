class OrdersController < ApplicationController
  def create
    if current_cart.empty?
      redirect_to cart_path, alert: "Giỏ hàng đang trống, bạn chọn vài món trước nha.", status: :see_other
      return
    end

    sold_out_names = current_cart.entries.filter_map { |product, _quantity| product.name if product.sold_out? }
    if sold_out_names.any?
      redirect_to cart_path, alert: "Món #{sold_out_names.join(', ')} vừa bán hết, bạn bỏ ra khỏi giỏ rồi đặt lại nha.",
                             status: :see_other
      return
    end

    @order = build_order_from_cart

    if @order.save
      current_cart.clear
      notify_admins(@order)
      redirect_to order_path(@order), notice: "Đặt hàng thành công!", status: :see_other
    else
      render "carts/show", status: :unprocessable_content
    end
  end

  def show
    @order = Order.includes(:order_items).find_by!(code: params[:code])
  end

  private

  def build_order_from_cart
    order = Order.new(order_params)

    current_cart.entries.each do |product, quantity|
      order.order_items.build(
        product: product,
        name: product.name,
        price: product.price,
        quantity: quantity
      )
    end

    order.recalculate_total
    order
  end

  def order_params
    params.expect(order: [ :customer_name, :phone, :email, :street, :province_code, :ward_code, :note ])
  end

  # Đơn đã lưu rồi, gửi mail hỏng cũng không được làm hỏng việc đặt hàng của khách
  def notify_admins(order)
    NotifyAdminsOfOrderJob.perform_later(order.id)
  rescue StandardError => e
    Rails.logger.error "[NotifyAdminsOfOrder] Không xếp được job cho đơn #{order.code}: #{e.message}"
  end
end
