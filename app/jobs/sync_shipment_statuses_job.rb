class SyncShipmentStatusesJob < ApplicationJob
  queue_as :default

  # Tra cứu trạng thái vận đơn GHTK cho các đơn đang giao — bù cho webhook bị lỡ.
  def perform
    client = Ghtk::Client.new

    pending_shipments.find_each do |order|
      sync(order, client)
    rescue Ghtk::NotConfiguredError => e
      Rails.logger.warn "[SyncShipmentStatuses] #{e.message}"
      break
    rescue Ghtk::Error => e
      Rails.logger.error "[SyncShipmentStatuses] Lỗi tra cứu đơn #{order.code}: #{e.message}"
    end
  end

  private

  def pending_shipments
    Order.shipped
         .where(carrier: Ghtk::CARRIER)
         .where.not(tracking_code: nil)
         .where("carrier_status_id IS NULL OR carrier_status_id NOT IN (?)", Ghtk::Status::FINAL)
  end

  def sync(order, client)
    response = client.order_status(order.tracking_code)
    unless response["success"] == true && response["order"].is_a?(Hash)
      raise Ghtk::Error, response["message"].presence || "GHTK không trả trạng thái"
    end

    data = response["order"]
    status_id = Integer(data["status"].to_s, 10)
    return if status_id == order.carrier_status_id

    Ghtk::Status.apply(
      order,
      status_id: status_id,
      at: Ghtk::Status.parse_time(data["modified"]),
      fee: (data["ship_money"] if data["ship_money"].to_s.match?(/\A\d+\z/))
    )
  rescue ArgumentError
    raise Ghtk::Error, "Mã trạng thái không hợp lệ: #{data && data['status'].inspect}"
  end
end
