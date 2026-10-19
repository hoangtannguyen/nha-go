# Dựng body cho API đăng đơn GHTK từ đơn hàng có sẵn trong DB.
# Địa chỉ dùng mô hình 2 cấp (tỉnh → phường/xã); `district` không bắt buộc theo tài liệu GHTK.
module Ghtk
  class OrderPayload
    def initialize(order, config)
      @order = order
      @config = config
    end

    def to_h
      validate!

      { products: products, order: order_attributes }
    end

    private

    attr_reader :order, :config

    def validate!
      raise Error, "Đơn chưa có món nào" if order.order_items.empty?
      raise Error, "Đơn thiếu tỉnh/thành hoặc phường/xã (đơn cũ) — không tạo được vận đơn" unless order.address_parts?
      raise Error, "Đơn thiếu số nhà/tên đường" if order.street.blank?
    end

    def products
      order.order_items.map do |item|
        { name: item.name, weight: item_weight, quantity: item.quantity, price: item.price }
      end
    end

    def order_attributes
      {
        id: order.code,
        **pick_attributes,
        name: order.customer_name,
        tel: order.phone,
        email: order.email.presence,
        address: order.street,
        province: order.province_name,
        ward: order.ward_name,
        hamlet: "Khác",
        note: order.note.presence,
        # Checkout là COD toàn quốc: thu hộ đúng tiền hàng của đơn
        pick_money: order.total,
        value: order.total,
        is_freeship: config.freeship? ? 1 : 0,
        weight_option: "kilogram",
        total_weight: total_weight,
        transport: config.transport
      }.compact
    end

    def pick_attributes
      attrs = config.pick
      attrs[:pick_address_id] = config.pick_address_id if config.pick_address_id.present?
      attrs
    end

    def item_weight
      config.default_item_weight_kg
    end

    def total_weight
      (order.order_items.sum(&:quantity) * item_weight).round(3)
    end
  end
end
