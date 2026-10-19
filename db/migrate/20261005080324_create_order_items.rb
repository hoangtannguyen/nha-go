class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price, null: false, default: 0
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
