class CartItemsController < ApplicationController
  before_action :set_product

  def create
    current_cart.add(@product) unless @product.sold_out?
    respond_with_cart
  end

  # Món đã bán hết chỉ cho giảm/bỏ, không cho tăng số lượng
  def update
    unless @product.sold_out? && params[:quantity].to_i > current_cart.quantity_for(@product)
      current_cart.update(@product, params[:quantity])
    end
    respond_with_cart
  end

  def destroy
    current_cart.remove(@product)
    respond_with_cart
  end

  private

  def set_product
    @product = Product.find(params[:product_id] || params[:id])
  end

  def respond_with_cart
    respond_to do |format|
      format.turbo_stream { render "cart_items/sync" }
      format.html { redirect_back fallback_location: root_path, status: :see_other }
    end
  end
end
