class AddShipmentFieldsToOrders < ActiveRecord::Migration[8.1]
  # Thông tin vận đơn bên giao hàng (hiện là GHTK) lưu thẳng trên đơn: mỗi đơn
  # chỉ có tối đa một vận đơn. `email` là email khách nhập lúc checkout (không bắt buộc).
  def change
    add_column :orders, :email, :string

    add_column :orders, :carrier, :string
    add_column :orders, :tracking_code, :string
    add_column :orders, :shipping_fee, :integer
    add_column :orders, :shipment_created_at, :datetime
    add_column :orders, :estimated_deliver_time, :string
    add_column :orders, :carrier_status_id, :integer
    add_column :orders, :carrier_status_reason, :string
    add_column :orders, :carrier_status_updated_at, :datetime
    add_column :orders, :shipment_error, :text
    add_column :orders, :shipping_notified_at, :datetime

    add_index :orders, :tracking_code, unique: true
  end
end
