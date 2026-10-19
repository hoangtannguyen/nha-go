module Admin
  class ProductPhotosController < BaseController
    def destroy
      product = Product.find(params[:product_id])
      photo = product.photos.find_by(id: params[:id])

      if photo
        photo.purge
        redirect_to edit_admin_product_path(product), notice: "Đã xoá 1 ảnh.", status: :see_other
      else
        redirect_to edit_admin_product_path(product), alert: "Không tìm thấy ảnh cần xoá.", status: :see_other
      end
    end
  end
end
