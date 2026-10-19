class AddSalePriceToProducts < ActiveRecord::Migration[8.1]
  # Giá khuyến mãi, để trống = không giảm giá
  def change
    add_column :products, :sale_price, :integer
  end
end
