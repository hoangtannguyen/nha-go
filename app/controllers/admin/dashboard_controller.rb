module Admin
  class DashboardController < BaseController
    def index
      today = Date.current

      @orders_today = Order.where(created_at: today.all_day).count
      @revenue_today = Order.where(created_at: today.all_day).where.not(status: :cancelled).sum(:total)
      @revenue_month = Order.where(created_at: today.all_month).where.not(status: :cancelled).sum(:total)
      @pending_count = Order.pending.count

      @counts_by_status = Order.group(:status).count
      @products_count = Product.count
      @customers_count = Customer.count

      @recent_orders = Order.recent.includes(:customer).limit(8)

      @best_sellers = OrderItem
        .joins(:order)
        .where.not(orders: { status: :cancelled })
        .group(:name)
        .order(Arel.sql("SUM(order_items.quantity) DESC"))
        .limit(5)
        .sum(:quantity)
    end
  end
end
