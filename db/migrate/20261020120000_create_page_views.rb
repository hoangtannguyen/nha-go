class CreatePageViews < ActiveRecord::Migration[8.1]
  def change
    # Mỗi lần khách tải trang (kể cả F5) là 1 dòng; visitor_id lấy từ cookie để ước tính khách duy nhất
    create_table :page_views do |t|
      t.string :visitor_id, null: false
      t.string :path, null: false
      t.references :product, foreign_key: { on_delete: :nullify }
      t.datetime :created_at, null: false
    end

    add_index :page_views, :created_at
    add_index :page_views, :visitor_id
  end
end
