class CartsController < ApplicationController
  def show
    @order = Order.new
  end
end
