module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [ :show, :update, :destroy ]

    def index
      @status = params[:status].presence_in(Order.statuses.keys)

      scope = Order.recent.includes(:customer, :order_items)
      scope = scope.where(status: @status) if @status
      scope = search(scope, params[:q])

      @orders = scope
      @counts_by_status = Order.group(:status).count
    end

    def show
      @order_items = @order.order_items.includes(:product)
    end

    def update
      @order.assign_attributes(order_params)
      # Chỉ chuyển sang "Đang giao" khi đã có vận đơn: tạo trước, lỗi thì giữ nguyên trạng thái cũ
      Ghtk::ShipmentCreator.new(@order).call if @order.status_changed? && @order.shipped?

      if @order.save
        notify_customer_of_shipment(@order) if @order.saved_change_to_status? && @order.shipped?
        redirect_to admin_order_path(@order), notice: "Đã cập nhật đơn #{@order.code}.", status: :see_other
      else
        @order_items = @order.order_items.includes(:product)
        render :show, status: :unprocessable_content
      end
    rescue Ghtk::Error => e
      @order.restore_attributes([ :status ])
      @order_items = @order.order_items.includes(:product)
      flash.now[:alert] = "Chưa tạo được vận đơn GHTK nên đơn chưa chuyển sang Đang giao: #{e.message}"
      render :show, status: :unprocessable_content
    end

    # Dùng để dọn đơn spam. Đơn đã có vận đơn GHTK thì không xoá để khỏi mất dấu vận đơn bên hãng vận chuyển.
    def destroy
      if @order.shipment?
        redirect_to admin_order_path(@order),
                    alert: "Không xoá được đơn #{@order.code} vì đã tạo vận đơn GHTK.", status: :see_other
        return
      end

      Order.transaction do
        customer = @order.customer
        @order.destroy!
        # Khách chỉ sinh ra từ đơn spam này thì xoá luôn cho sạch danh sách khách hàng
        customer.destroy! if customer && !customer.orders.exists?
      end
      redirect_to admin_orders_path, notice: "Đã xoá đơn #{@order.code}.", status: :see_other
    end

    private

    def set_order
      @order = Order.find_by!(code: params[:code])
    end

    def search(scope, query)
      return scope if query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(query.strip)}%"
      scope.where("code LIKE :t OR customer_name LIKE :t OR phone LIKE :t", t: term)
    end

    def order_params
      params.expect(order: [ :status ])
    end

    # Job tự chống gửi trùng; xếp job lỗi cũng không được làm hỏng việc cập nhật đơn
    def notify_customer_of_shipment(order)
      return if order.email.blank? || !order.shipment?

      NotifyCustomerOfShipmentJob.perform_later(order.id)
    rescue StandardError => e
      Rails.logger.error "[NotifyCustomerOfShipment] Không xếp được job cho đơn #{order.code}: #{e.message}"
    end
  end
end
