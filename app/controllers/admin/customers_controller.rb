module Admin
  class CustomersController < BaseController
    def index
      scope = Customer.ordered.left_joins(:orders)
                      .select("customers.*",
                              "COUNT(orders.id) AS orders_total",
                              "COALESCE(SUM(orders.total), 0) AS spent_total",
                              "MAX(orders.created_at) AS last_order_at")
                      .group("customers.id")

      @customers = search(scope, params[:q])
    end

    def show
      @customer = Customer.find(params[:id])
      @orders = @customer.orders.recent.includes(:order_items)
    end

    private

    def search(scope, query)
      return scope if query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(query.strip)}%"
      scope.where("customers.name LIKE :t OR customers.phone LIKE :t", t: term)
    end
  end
end
