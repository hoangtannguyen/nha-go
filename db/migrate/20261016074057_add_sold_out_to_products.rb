class AddSoldOutToProducts < ActiveRecord::Migration[8.1]
  # Admin tích "Đã bán hết": vẫn hiện ngoài shop (xếp cuối) nhưng không cho mua
  def change
    add_column :products, :sold_out, :boolean, default: false, null: false
  end
end
