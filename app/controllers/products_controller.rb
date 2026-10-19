class ProductsController < ApplicationController
  # Lọc và sắp xếp bằng query param để link chia sẻ/chạy quảng cáo được
  SORT_OPTIONS = {
    "noi-bat"  => { label: "Nổi bật",        order: { position: :asc, id: :asc } },
    "moi-nhat" => { label: "Mới nhất",       order: { created_at: :desc, id: :desc } },
    "gia-thap" => { label: "Giá thấp → cao", order: Arel.sql("COALESCE(products.sale_price, products.price) ASC, products.id ASC") },
    "gia-cao"  => { label: "Giá cao → thấp", order: Arel.sql("COALESCE(products.sale_price, products.price) DESC, products.id DESC") }
  }.freeze

  DEFAULT_SORT = "noi-bat".freeze

  def index
    @categories = Category.ordered
    @category = @categories.find { |category| category.slug == params[:category] }
    @sort = params[:sort].presence_in(SORT_OPTIONS.keys) || DEFAULT_SORT

    scope = Product.visible.with_attached_photos.includes(:category)
    scope = scope.in_category(@category) if @category

    @products = scope.available_first.order(SORT_OPTIONS.dig(@sort, :order))
    @total_count = Product.visible.count
    @counts_by_category = Product.visible.group(:category_id).count
  end

  def show
    @product = Product.visible.with_attached_photos.includes(:category).find(params[:id])

    @related = Product.visible.available_first.ordered
                      .with_attached_photos
                      .in_category(@product.category)
                      .where.not(id: @product.id)
                      .limit(3)
  end
end
