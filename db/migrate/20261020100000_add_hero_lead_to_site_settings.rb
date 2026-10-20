class AddHeroLeadToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    # Để trống = dùng nội dung mặc định trong SiteSetting::TEXTS
    add_column :site_settings, :hero_lead, :string
  end
end
