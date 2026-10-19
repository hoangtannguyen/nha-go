class ShopsController < ApplicationController
  def index
    @categories = Category.ordered
    @products = Product.visible.available_first.ordered.with_attached_photos.includes(:category).limit(10)
    @total_count = Product.visible.count
  end
end
