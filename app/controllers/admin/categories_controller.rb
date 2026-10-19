module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      @categories = Category.ordered.left_joins(:products)
                            .select("categories.*", "COUNT(products.id) AS products_total")
                            .group("categories.id")
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: "Đã thêm danh mục \"#{@category.name}\".", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Đã cập nhật \"#{@category.name}\".", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @category.products.exists?
        redirect_to admin_categories_path,
                    alert: "Không xoá được \"#{@category.name}\" vì còn #{@category.products.count} sản phẩm thuộc danh mục này.",
                    status: :see_other
      else
        @category.destroy
        redirect_to admin_categories_path, notice: "Đã xoá danh mục.", status: :see_other
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.expect(category: [ :name, :slug, :description, :position ])
    end
  end
end
