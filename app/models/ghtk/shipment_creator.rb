# Tạo vận đơn GHTK cho một đơn và lưu kết quả lên đơn.
#
# Chống tạo trùng 2 lớp:
#   1. Đơn đã có tracking_code thì không gọi API nữa.
#   2. Mã đơn (order.code) được gửi làm `order.id` phía GHTK. Nếu lần trước GHTK
#      đã tạo nhưng mình không nhận được response (timeout, bấm 2 lần...), lần sau
#      GHTK trả ORDER_ID_EXIST kèm mã vận đơn cũ -> lấy lại mã đó, không tạo mới.
module Ghtk
  class ShipmentCreator
    def initialize(order, client: Client.new)
      @order = order
      @client = client
    end

    # Trả về true khi vừa ghi nhận vận đơn, false nếu đơn đã có sẵn. Lỗi thì raise Ghtk::Error.
    def call
      return false if order.tracking_code.present?

      response = client.create_order(OrderPayload.new(order, client.config).to_h)

      if response["success"] == true && response.dig("order", "label").present?
        record_created(response["order"])
      elsif response.dig("error", "code") == "ORDER_ID_EXIST" && response.dig("error", "ghtk_label").present?
        record_existing(response["error"])
      else
        raise Error, response["message"].presence || "GHTK không tạo được vận đơn"
      end

      true
    rescue Error => e
      order.update_columns(shipment_error: e.message.truncate(500)) if order.persisted?
      raise
    end

    private

    attr_reader :order, :client

    def record_created(data)
      now = Time.current
      save_shipment(
        tracking_code: data["label"],
        shipping_fee: integer_or_nil(data["fee"]),
        estimated_deliver_time: data["estimated_deliver_time"].presence,
        carrier_status_id: integer_or_nil(data["status_id"]),
        carrier_status_updated_at: now,
        shipment_created_at: now
      )
    end

    def record_existing(error)
      created_at = Status.parse_time(error["created"]) || Time.current
      save_shipment(
        tracking_code: error["ghtk_label"],
        carrier_status_id: integer_or_nil(error["status"]),
        carrier_status_updated_at: created_at,
        shipment_created_at: created_at
      )
    end

    def save_shipment(attrs)
      order.update_columns(attrs.merge(carrier: CARRIER, shipment_error: nil, updated_at: Time.current))
    end

    def integer_or_nil(value)
      Integer(value.to_s, 10)
    rescue ArgumentError
      nil
    end
  end
end
