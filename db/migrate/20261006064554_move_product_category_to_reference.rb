class MoveProductCategoryToReference < ActiveRecord::Migration[8.1]
  # products.category là enum integer. Chuyển sang khoá ngoại tới bảng categories,
  # giữ nguyên slug cũ để link đã chia sẻ (/products?category=aokhoac) không chết.
  OLD_CATEGORIES = [
    [ 0, "aokhoac",    "Áo khoác" ],
    [ 1, "aothun",     "Áo thun" ],
    [ 2, "quandai",    "Quần dài" ],
    [ 3, "somiveston", "Sơ mi / Hoodie" ]
  ].freeze

  def up
    add_reference :products, :category, foreign_key: true

    OLD_CATEGORIES.each_with_index do |(value, slug, name), index|
      execute <<~SQL
        INSERT INTO categories (name, slug, position, created_at, updated_at)
        SELECT #{quote(name)}, #{quote(slug)}, #{index + 1}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = #{quote(slug)})
      SQL

      execute <<~SQL
        UPDATE products
        SET category_id = (SELECT id FROM categories WHERE slug = #{quote(slug)})
        WHERE category = #{value}
      SQL
    end

    # Món nào chưa khớp thì gán tạm vào danh mục đầu tiên để không còn NULL
    execute <<~SQL
      UPDATE products
      SET category_id = (SELECT id FROM categories ORDER BY position, id LIMIT 1)
      WHERE category_id IS NULL
    SQL

    change_column_null :products, :category_id, false
    remove_column :products, :category
  end

  def down
    add_column :products, :category, :integer, null: false, default: 0

    OLD_CATEGORIES.each do |(value, slug, _name)|
      execute <<~SQL
        UPDATE products
        SET category = #{value}
        WHERE category_id = (SELECT id FROM categories WHERE slug = #{quote(slug)})
      SQL
    end

    remove_reference :products, :category, foreign_key: true
  end

  private

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
