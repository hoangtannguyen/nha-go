class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :code, null: false
      t.string :customer_name, null: false
      t.string :phone, null: false
      t.text :address, null: false
      t.text :note
      t.integer :total, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :orders, :code, unique: true
    add_index :orders, :status
  end
end
