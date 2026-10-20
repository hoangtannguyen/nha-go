module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin
    skip_after_action :track_page_view

    helper_method :current_admin

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      @current_admin = AdminUser.enabled.find_by(id: session[:admin_user_id])
    end

    def require_admin
      return if current_admin

      session[:admin_return_to] = request.fullpath if request.get? || request.head?
      redirect_to admin_login_path, alert: "Vui lòng đăng nhập để vào trang quản trị."
    end
  end
end
