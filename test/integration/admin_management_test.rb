require "test_helper"

class AdminManagementTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @jacket = products(:denim_jacket)
    @jeans = products(:jeans)

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  # ===== đơn hàng =====

  test "danh sách đơn lọc theo trạng thái và tìm theo mã/SĐT" do
    order = create_order(phone: "0911111111", name: "Khách A")
    other = create_order(phone: "0922222222", name: "Khách B")
    other.update!(status: :shipped)

    get admin_orders_path
    assert_response :success
    assert_select "tbody tr", 2

    get admin_orders_path(status: "shipped")
    assert_select "tbody tr", 1
    assert_match other.code, response.body

    get admin_orders_path(q: "0911111111")
    assert_select "tbody tr", 1
    assert_match order.code, response.body

    get admin_orders_path(q: order.code)
    assert_select "tbody tr", 1
  end

  test "xem chi tiết đơn và đổi trạng thái" do
    order = create_order

    get admin_order_path(order)
    assert_response :success
    assert_match order.customer_name, response.body

    patch admin_order_path(order), params: { order: { status: "confirmed" } }
    assert_redirected_to admin_order_path(order)
    assert_equal "confirmed", order.reload.status
  end

  # ===== sản phẩm =====

  test "tạo sản phẩm mới kèm upload ảnh" do
    assert_difference "Product.count", 1 do
      post admin_products_path, params: {
        product: {
          name: "Áo len cổ lọ",
          category_id: categories(:tee).id,
          price: 175_000,
          size_label: "Size M · Nữ",
          tag: "HOT",
          position: 9,
          photos: [ fixture_file_upload("product.png", "image/png") ]
        }
      }
    end

    product = Product.find_by(name: "Áo len cổ lọ")
    assert_redirected_to admin_products_path
    assert product.photos.attached?, "ảnh phải được đính kèm"
    assert_equal 175_000, product.price
    assert_equal categories(:tee), product.category
  end

  test "từ chối file không phải ảnh" do
    assert_no_difference "Product.count" do
      post admin_products_path, params: {
        product: { name: "File lạ", category_id: categories(:tee).id, price: 1000,
                   photos: [ fixture_file_upload("notes.txt", "text/plain") ] }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "sửa và xoá sản phẩm" do
    patch admin_product_path(@jeans), params: { product: { price: 199_000 } }
    assert_redirected_to admin_products_path
    assert_equal 199_000, @jeans.reload.price

    assert_difference "Product.count", -1 do
      delete admin_product_path(@jeans)
    end
  end

  test "không xoá được sản phẩm đã nằm trong đơn" do
    create_order

    assert_no_difference "Product.count" do
      delete admin_product_path(@jacket)
    end

    assert_redirected_to admin_products_path
    assert_match "đã có đơn đặt món này", flash[:alert]
  end

  # ===== khách hàng =====

  test "đặt hàng tự tạo customer và gộp theo số điện thoại" do
    assert_difference "Customer.count", 1 do
      create_order(phone: "0933333333", name: "Khách Quen")
      create_order(phone: "0933333333", name: "Khách Quen")
    end

    customer = Customer.find_by(phone: "0933333333")
    assert_equal 2, customer.orders_count

    get admin_customers_path
    assert_response :success
    assert_select "tbody tr", 1

    get admin_customer_path(customer)
    assert_response :success
    assert_select "tbody tr", 2
  end

  test "tìm khách hàng theo tên" do
    create_order(phone: "0944444444", name: "Phạm Thuỳ Linh")
    create_order(phone: "0955555555", name: "Trần Văn Nam")

    get admin_customers_path(q: "Thuỳ")
    assert_select "tbody tr", 1
  end

  # ===== tài khoản admin =====

  test "tạo tài khoản admin mới rồi đăng nhập được" do
    assert_difference "AdminUser.count", 1 do
      post admin_admin_users_path, params: {
        admin_user: { name: "Admin Mới", email: "moi@nhago.local",
                      password: "matkhaumoi123", password_confirmation: "matkhaumoi123", active: "1" }
      }
    end

    delete admin_logout_path
    post admin_login_path, params: { email: "moi@nhago.local", password: "matkhaumoi123" }
    assert_redirected_to admin_root_path
  end

  test "mật khẩu quá ngắn bị từ chối" do
    assert_no_difference "AdminUser.count" do
      post admin_admin_users_path, params: {
        admin_user: { name: "Yếu", email: "yeu@nhago.local",
                      password: "123", password_confirmation: "123", active: "1" }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "sửa tài khoản mà để trống mật khẩu thì giữ nguyên mật khẩu cũ" do
    staff = admin_users(:staff)

    patch admin_admin_user_path(staff), params: {
      admin_user: { name: "Nhân viên B", email: staff.email, password: "", password_confirmation: "", active: "1" }
    }

    assert_redirected_to admin_admin_users_path
    assert_equal "Nhân viên B", staff.reload.name
    assert staff.authenticate("matkhau12345"), "mật khẩu cũ phải còn dùng được"
  end

  test "không tự xoá được tài khoản đang đăng nhập" do
    assert_no_difference "AdminUser.count" do
      delete admin_admin_user_path(@owner)
    end

    assert_match "Không thể tự xoá", flash[:alert]
  end

  # ===== dashboard =====

  test "dashboard hiện số liệu đúng" do
    create_order
    cancelled = create_order(phone: "0966666666", name: "Khách Huỷ")
    cancelled.update!(status: :cancelled)

    get admin_root_path
    assert_response :success

    # doanh thu không tính đơn đã huỷ
    assert_select ".stat-card", 4
    assert_match price_vnd(Order.where.not(status: :cancelled).sum(:total)), response.body
  end

  private

  def price_vnd(amount)
    "#{ActiveSupport::NumberHelper.number_to_delimited(amount, delimiter: '.')}đ"
  end

  def create_order(phone: "0901234567", name: "Khách Test")
    order = Order.new(customer_name: name, phone: phone, street: "97 Ngô Đức Kế", province_code: 46, ward_code: 19753)
    order.order_items.build(product: @jacket, name: @jacket.name, price: @jacket.price, quantity: 1)
    order.recalculate_total
    order.save!
    order
  end
end
