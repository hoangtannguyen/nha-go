class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.string :tag
      t.string :image
      t.string :size_label
      t.integer :price, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :products, :category
    add_index :products, :position
  end
end
