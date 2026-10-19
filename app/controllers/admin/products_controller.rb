module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [ :edit, :update, :destroy ]

    def index
      @categories = Category.ordered
      @category = @categories.find { |category| category.slug == params[:category] }

      scope = Product.ordered.with_attached_photos.includes(:category)
      scope = scope.in_category(@category) if @category

      @products = scope
    end

    def new
      # price: nil để ô giá trống thay vì hiện sẵn số 0 mặc định của cột
      @product = Product.new(position: (Product.maximum(:position) || 0) + 1, price: nil)
    end

    def create
      @product = Product.new(product_params)
      @product.photos.attach(uploaded_photos) if uploaded_photos.any?

      if @product.save
        redirect_to admin_products_path, notice: "Đã thêm \"#{@product.name}\".", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      @product.assign_attributes(product_params)
      # attach để BỔ SUNG; gán thẳng photos = [...] sẽ thay thế hết ảnh cũ
      @product.photos.attach(uploaded_photos) if uploaded_photos.any?

      if @product.save
        redirect_to admin_products_path, notice: "Đã cập nhật \"#{@product.name}\".", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @product.order_items.exists?
        redirect_to admin_products_path,
                    alert: "Không xoá được \"#{@product.name}\" vì đã có đơn đặt món này.", status: :see_other
      else
        @product.destroy
        redirect_to admin_products_path, notice: "Đã xoá \"#{@product.name}\".", status: :see_other
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      attributes = params.expect(product: [ :name, :category_id, :tag, :size_label, :price, :position, :sold_out, :hidden,
                                            { colors: [], sizes: [], photos: [] } ])

      # "285.000" từ ô nhập có phân cách -> 285000, phải bỏ dấu TRƯỚC khi gán
      # vì gán thẳng vào cột integer sẽ bị cắt thành 285.
      attributes[:price] = attributes[:price].to_s.gsub(/\D/, "") if attributes.key?(:price)

      attributes.except(:photos)
    end

    def uploaded_photos
      @uploaded_photos ||= Array(params.dig(:product, :photos)).reject(&:blank?)
    end
  end
end
