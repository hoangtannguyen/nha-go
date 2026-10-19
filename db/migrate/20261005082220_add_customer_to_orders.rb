class AddCustomerToOrders < ActiveRecord::Migration[8.1]
  def up
    add_reference :orders, :customer, foreign_key: true

    # Gắn đơn cũ vào customer tương ứng, gom theo số điện thoại
    execute <<~SQL
      INSERT INTO customers (phone, name, address, created_at, updated_at)
      SELECT o.phone, MIN(o.customer_name), MIN(o.address), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM orders o
      WHERE o.customer_id IS NULL
      GROUP BY o.phone
    SQL

    execute <<~SQL
      UPDATE orders
      SET customer_id = (SELECT c.id FROM customers c WHERE c.phone = orders.phone)
      WHERE customer_id IS NULL
    SQL
  end

  def down
    remove_reference :orders, :customer, foreign_key: true
  end
end
