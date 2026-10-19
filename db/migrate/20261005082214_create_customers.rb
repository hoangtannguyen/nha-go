class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :phone, null: false
      t.string :name, null: false
      t.text :address
      t.text :note

      t.timestamps
    end

    add_index :customers, :phone, unique: true
  end
end
