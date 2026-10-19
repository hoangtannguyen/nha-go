class ShopsController < ApplicationController
  def index
    @categories = Category.ordered
    @products = Product.visible.available_first.ordered.with_attached_photos.includes(:category)
    @total_count = @products.size
  end
end
