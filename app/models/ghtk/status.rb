# Bảng mã trạng thái đơn GHTK (status_id) và ghi nhận cập nhật trạng thái lên đơn.
# Nguồn: https://api.ghtk.vn/docs/submit-order/webhook
module Ghtk
  module Status
    LABELS = {
      -1  => "Đã huỷ vận đơn",
      1   => "Chưa tiếp nhận",
      2   => "Đã tiếp nhận",
      3   => "Đã lấy hàng / nhập kho",
      4   => "Đang giao hàng",
      5   => "Đã giao hàng",
      6   => "Đã giao hàng, đã đối soát",
      7   => "Không lấy được hàng",
      8   => "Hoãn lấy hàng",
      9   => "Không giao được hàng",
      10  => "Hoãn giao hàng",
      11  => "Đã đối soát công nợ trả hàng",
      12  => "Đang lấy hàng",
      13  => "Đơn bồi hoàn",
      20  => "Đang trả hàng về shop",
      21  => "Đã trả hàng về shop",
      123 => "Shipper báo đã lấy hàng",
      127 => "Shipper báo không lấy được hàng",
      128 => "Shipper báo hoãn lấy hàng",
      45  => "Shipper báo đã giao hàng",
      49  => "Shipper báo không giao được hàng",
      410 => "Shipper báo hoãn giao hàng"
    }.freeze

    # Không còn thay đổi nữa -> thôi tra cứu định kỳ
    FINAL = [ -1, 6, 11, 13, 21 ].freeze

    module_function

    def label(status_id)
      return if status_id.nil?

      LABELS.fetch(status_id.to_i, "Mã trạng thái #{status_id}")
    end

    # Ghi trạng thái mới nhất lên đơn. Bỏ qua cập nhật cũ hơn cái đang lưu
    # (webhook có thể tới không theo thứ tự hoặc bị gửi lại).
    def apply(order, status_id:, at: nil, reason: nil, fee: nil)
      at ||= Time.current
      return false if order.carrier_status_updated_at && at < order.carrier_status_updated_at

      status_id = Integer(status_id)
      attrs = { carrier_status_id: status_id, carrier_status_updated_at: at }
      attrs[:carrier_status_reason] = reason.presence if reason.present? || status_id != order.carrier_status_id
      attrs[:shipping_fee] = Integer(fee) if fee.present?

      order.update_columns(attrs)
      true
    end

    def parse_time(value)
      return if value.blank?

      time = Time.zone.parse(value.to_s)
      time if time && time.year >= 2000
    rescue ArgumentError
      nil
    end
  end
end
