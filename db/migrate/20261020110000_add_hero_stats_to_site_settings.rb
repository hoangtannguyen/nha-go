class AddHeroStatsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    # 3 ô số liệu dưới banner trang chủ. Để trống = dùng mặc định trong SiteSetting::TEXTS
    1.upto(3) do |index|
      add_column :site_settings, "hero_stat_#{index}_value", :string
      add_column :site_settings, "hero_stat_#{index}_label", :string
    end
  end
end
