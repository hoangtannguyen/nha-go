# Nhận cập nhật trạng thái vận đơn từ GHTK.
# GHTK gọi POST tới URL đã đăng ký, dạng /webhooks/ghtk?hash=<GHTK_WEBHOOK_HASH>.
# Không có session/cookie nên dùng ActionController::API (không CSRF, không allow_browser).
module Webhooks
  class GhtkController < ActionController::API
    def create
      return head :unauthorized unless valid_hash?
      return head :bad_request unless params[:status_id].to_s.match?(/\A-?\d+\z/)

      order = Order.find_by(code: params[:partner_id].to_s, tracking_code: params[:label_id].to_s)

      if order
        Ghtk::Status.apply(
          order,
          status_id: params[:status_id],
          at: Ghtk::Status.parse_time(params[:action_time]),
          reason: params[:reason].to_s.truncate(255).presence,
          fee: (params[:fee] if params[:fee].to_s.match?(/\A\d+\z/))
        )
      else
        Rails.logger.warn "[GhtkWebhook] Không thấy đơn #{params[:partner_id]} / vận đơn #{params[:label_id]}"
      end

      # GHTK chỉ cần HTTP 200; trả lỗi với đơn không tồn tại chỉ khiến GHTK gửi lại vô ích
      head :ok
    end

    private

    def valid_hash?
      expected = Ghtk::Config.new.webhook_hash
      expected.present? && ActiveSupport::SecurityUtils.secure_compare(params[:hash].to_s, expected)
    end
  end
end
