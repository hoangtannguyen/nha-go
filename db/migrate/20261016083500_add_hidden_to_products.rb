class AddHiddenToProducts < ActiveRecord::Migration[8.1]
  # Chỉ có tác dụng khi sold_out: ẩn hẳn món khỏi trang bán hàng (link cũ trả 404)
  def change
    add_column :products, :hidden, :boolean, default: false, null: false
  end
end
