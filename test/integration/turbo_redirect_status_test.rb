require "test_helper"

# Turbo dùng fetch để submit form. Theo spec, 302 sau PATCH/DELETE được follow lại
# BẰNG CHÍNH PATCH/DELETE tới địa chỉ mới -> không khớp route -> submit thất bại.
# Chỉ 303 See Other mới ép đổi sang GET, nên mọi redirect sau non-GET phải là 303.
class TurboRedirectStatusTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @jacket = products(:denim_jacket)
    @jeans = products(:jeans)
  end

  test "sửa sản phẩm trả 303 chứ không phải 302" do
    login
    patch admin_product_path(@jeans), params: { product: { name: "Tên mới" } }

    assert_response :see_other
  end

  test "xoá sản phẩm trả 303" do
    login
    delete admin_product_path(@jeans)

    assert_response :see_other
  end

  test "xoá ảnh sản phẩm trả 303" do
    login
    @jeans.photos.attach(fixture_file_upload("product.png", "image/png"))

    delete admin_product_photo_path(@jeans, @jeans.photos.first)

    assert_response :see_other
  end

  test "đổi trạng thái đơn trả 303" do
    login
    order = create_order

    patch admin_order_path(order), params: { order: { status: "confirmed" } }

    assert_response :see_other
  end

  test "sửa và xoá tài khoản admin trả 303" do
    login
    staff = admin_users(:staff)

    patch admin_admin_user_path(staff), params: { admin_user: { name: "Tên khác", email: staff.email } }
    assert_response :see_other

    delete admin_admin_user_path(staff)
    assert_response :see_other
  end

  test "đăng nhập và đăng xuất trả 303" do
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
    assert_response :see_other

    delete admin_logout_path
    assert_response :see_other
  end

  test "thao tác giỏ hàng dạng HTML trả 303" do
    post cart_items_path, params: { product_id: @jacket.id }
    assert_response :see_other

    patch cart_item_path(@jacket), params: { quantity: 2 }
    assert_response :see_other

    delete cart_item_path(@jacket)
    assert_response :see_other
  end

  test "đặt hàng trả 303" do
    post cart_items_path, params: { product_id: @jacket.id }
    post orders_path, params: {
      order: { customer_name: "Khách", phone: "0901234567", street: "97 Ngô Đức Kế", province_code: 46, ward_code: 19753 }
    }

    assert_response :see_other
  end

  private

  def login
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  def create_order
    order = Order.new(customer_name: "Khách Test", phone: "0901234567", street: "97 Ngô Đức Kế", province_code: 46, ward_code: 19753)
    order.order_items.build(product: @jacket, name: @jacket.name, price: @jacket.price, quantity: 1)
    order.recalculate_total
    order.save!
    order
  end
end
