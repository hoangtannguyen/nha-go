# Ghi nhận lượt xem trang phía khách (mỗi lần tải trang/F5 = 1 lượt).
# Không tính admin đang đăng nhập, request không phải HTML, và Turbo prefetch khi rê chuột.
module PageViewTracking
  extend ActiveSupport::Concern

  VISITOR_COOKIE = :visitor_id

  included do
    after_action :track_page_view
  end

  private

  def track_page_view
    return unless trackable_page_view?

    PageView.create!(visitor_id: visitor_id, path: request.path.first(255), product: page_view_product)
  rescue ActiveRecord::ActiveRecordError => e
    # Thống kê không được làm hỏng trang của khách
    Rails.logger.warn("[PageViewTracking] #{e.class}: #{e.message}")
  end

  def trackable_page_view?
    request.get? &&
      request.format.html? &&
      response.successful? &&
      request.headers["X-Sec-Purpose"] != "prefetch" &&
      session[:admin_user_id].blank?
  end

  # Cookie ẩn danh, chỉ dùng để ước tính số trình duyệt truy cập duy nhất
  def visitor_id
    id = cookies[VISITOR_COOKIE].to_s.first(64).presence || SecureRandom.uuid
    cookies.permanent[VISITOR_COOKIE] = { value: id, httponly: true, same_site: :lax }
    id
  end

  # Controller nào cần gắn lượt xem với sản phẩm thì override
  def page_view_product
    nil
  end
end
