module Admin
  class SubscribersController < BaseController
    before_action :set_subscriber, only: [ :toggle, :destroy ]

    def index
      @status = params[:status].presence_in(%w[active inactive])

      scope = Subscriber.recent
      scope = scope.active if @status == "active"
      scope = scope.inactive if @status == "inactive"

      @subscribers = search(scope, params[:q])
      @active_count = Subscriber.active.count
      @inactive_count = Subscriber.inactive.count
    end

    def toggle
      if @subscriber.active?
        @subscriber.unsubscribe!
        notice = "Đã tạm dừng gửi tin cho #{@subscriber.email}."
      else
        @subscriber.resubscribe!
        notice = "Đã bật lại nhận tin cho #{@subscriber.email}."
      end

      redirect_to admin_subscribers_path, notice: notice, status: :see_other
    end

    def destroy
      email = @subscriber.email
      @subscriber.destroy
      redirect_to admin_subscribers_path, notice: "Đã xoá #{email} khỏi danh sách.", status: :see_other
    end

    # Form chọn sản phẩm để báo tin
    def broadcast
      @products = Product.order(created_at: :desc).with_attached_photos.includes(:category).limit(20)
      @active_count = Subscriber.active.count
    end

    def send_broadcast
      product_ids = Array(params[:product_ids]).reject(&:blank?)
      recipients = Subscriber.active

      if product_ids.empty?
        redirect_to broadcast_admin_subscribers_path,
                    alert: "Chọn ít nhất 1 sản phẩm để báo tin.", status: :see_other
        return
      end

      if recipients.none?
        redirect_to broadcast_admin_subscribers_path,
                    alert: "Chưa có thành viên nào đang nhận tin.", status: :see_other
        return
      end

      BroadcastNewArrivalsJob.perform_later(product_ids, recipients.pluck(:id))

      redirect_to admin_subscribers_path,
                  notice: "Đã xếp hàng gửi #{product_ids.size} món tới #{recipients.count} thành viên.",
                  status: :see_other
    end

    private

    def set_subscriber
      @subscriber = Subscriber.find(params[:id])
    end

    def search(scope, query)
      return scope if query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(query.strip)}%"
      scope.where("email LIKE :t OR name LIKE :t OR phone LIKE :t", t: term)
    end
  end
end
