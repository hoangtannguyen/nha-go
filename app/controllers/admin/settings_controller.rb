module Admin
  class SettingsController < BaseController
    before_action :set_setting

    def edit
    end

    def update
      if @setting.update(setting_params)
        redirect_to edit_admin_settings_path, notice: "Đã lưu cài đặt.", status: :see_other
      else
        # Ảnh vừa chọn chưa lưu không render được -> lấy lại bản ghi sạch từ DB,
        # chỉ giữ lại phần chữ admin vừa gõ
        @errors = @setting.errors.full_messages
        @setting = SiteSetting.instance
        @setting.assign_attributes(setting_params.slice(*SiteSetting::TEXTS.keys))
        render :edit, status: :unprocessable_content
      end
    end

    # Xoá ảnh đã upload, quay về ảnh mặc định
    def reset_image
      name = params[:image]

      if SiteSetting::IMAGES.key?(name)
        @setting.image(name).purge
        redirect_to edit_admin_settings_path,
                    notice: "Đã khôi phục #{SiteSetting::IMAGES[name][:label].downcase} mặc định.",
                    status: :see_other
      else
        redirect_to edit_admin_settings_path, alert: "Không tìm thấy ảnh cần khôi phục.", status: :see_other
      end
    end

    private

    def set_setting
      @setting = SiteSetting.instance
    end

    def setting_params
      @setting_params ||= params.fetch(:site_setting, {})
                                .permit(*SiteSetting::IMAGES.keys, *SiteSetting::TEXTS.keys)
                                .reject { |name, file| SiteSetting::IMAGES.key?(name) && file.blank? }
    end
  end
end
