class AddAddressPartsToOrders < ActiveRecord::Migration[8.1]
  # Tách địa chỉ thành số nhà/đường + phường/xã + tỉnh/thành.
  # Cột `address` giữ nguyên, chứa địa chỉ đầy đủ đã ghép — mọi chỗ hiển thị
  # và email đơn hàng vẫn dùng nó nên đơn cũ không bị ảnh hưởng.
  def change
    add_column :orders, :street, :string
    add_column :orders, :ward_code, :integer
    add_column :orders, :ward_name, :string
    add_column :orders, :province_code, :integer
    add_column :orders, :province_name, :string

    add_index :orders, :province_code
  end
end
