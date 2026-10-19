module Admin
  class SessionsController < BaseController
    layout "admin_login"

    skip_before_action :require_admin, only: [ :new, :create ]

    def new
      redirect_to admin_root_path and return if current_admin

      @email = ""
    end

    def create
      admin = AdminUser.authenticate(params[:email], params[:password])

      if admin
        return_to = session[:admin_return_to]
        reset_session
        session[:admin_user_id] = admin.id
        admin.touch_login!
        redirect_to return_to || admin_root_path, notice: "Chào #{admin.name}!", status: :see_other
      else
        @email = params[:email].to_s
        flash.now[:alert] = "Email hoặc mật khẩu không đúng."
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "Đã đăng xuất.", status: :see_other
    end
  end
end
