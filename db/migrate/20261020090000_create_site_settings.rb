class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    # Bảng 1 dòng duy nhất, chỉ để gắn ảnh logo/banner qua Active Storage
    create_table :site_settings do |t|
      t.timestamps
    end
  end
end
