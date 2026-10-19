module Admin
  class AdminUsersController < BaseController
    before_action :set_admin_user, only: [ :edit, :update, :destroy ]

    def index
      @admin_users = AdminUser.ordered
    end

    def new
      @admin_user = AdminUser.new
    end

    def create
      @admin_user = AdminUser.new(admin_user_params)

      if @admin_user.save
        redirect_to admin_admin_users_path, notice: "Đã tạo tài khoản #{@admin_user.name}.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @admin_user.update(admin_user_params_for_update)
        redirect_to admin_admin_users_path, notice: "Đã cập nhật #{@admin_user.name}.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @admin_user == current_admin
        redirect_to admin_admin_users_path, alert: "Không thể tự xoá tài khoản đang đăng nhập.", status: :see_other
      elsif AdminUser.enabled.count <= 1
        redirect_to admin_admin_users_path, alert: "Phải còn ít nhất 1 tài khoản quản trị.", status: :see_other
      else
        @admin_user.destroy
        redirect_to admin_admin_users_path, notice: "Đã xoá tài khoản.", status: :see_other
      end
    end

    private

    def set_admin_user
      @admin_user = AdminUser.find(params[:id])
    end

    def admin_user_params
      params.expect(admin_user: [ :name, :email, :password, :password_confirmation, :active ])
    end

    # Để trống mật khẩu nghĩa là giữ nguyên mật khẩu cũ
    def admin_user_params_for_update
      attributes = admin_user_params

      if attributes[:password].blank?
        attributes.except(:password, :password_confirmation)
      else
        attributes
      end
    end
  end
end
