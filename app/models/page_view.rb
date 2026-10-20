class PageView < ApplicationRecord
  belongs_to :product, optional: true

  scope :on_products, -> { where.not(product_id: nil) }

  # [[product, số lượt xem], ...] — sản phẩm đã xoá thì bỏ qua
  def self.top_products(limit = 5)
    counts = on_products.group(:product_id).order(Arel.sql("COUNT(*) DESC")).limit(limit).count
    products = Product.where(id: counts.keys).index_by(&:id)

    counts.filter_map { |product_id, views| [ products[product_id], views ] if products[product_id] }
  end
end
