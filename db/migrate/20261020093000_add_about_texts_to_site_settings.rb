class AddAboutTextsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    # Để trống = dùng nội dung mặc định trong SiteSetting::TEXTS
    add_column :site_settings, :about_title, :string
    add_column :site_settings, :about_title_highlight, :string
    add_column :site_settings, :about_body, :text
    add_column :site_settings, :about_quote, :string
  end
end
