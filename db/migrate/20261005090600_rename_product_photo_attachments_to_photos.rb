class RenameProductPhotoAttachmentsToPhotos < ActiveRecord::Migration[8.1]
  # Product chuyển từ has_one_attached :photo sang has_many_attached :photos.
  # Ảnh upload trước đó nằm dưới tên "photo" nên phải đổi tên, không thì mất ảnh.
  def up
    ActiveStorage::Attachment
      .where(record_type: "Product", name: "photo")
      .update_all(name: "photos")
  end

  def down
    ActiveStorage::Attachment
      .where(record_type: "Product", name: "photos")
      .update_all(name: "photo")
  end
end
