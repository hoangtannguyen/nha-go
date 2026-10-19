class AddColorsAndSizesToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :colors, :json
    add_column :products, :sizes, :json
  end
end
