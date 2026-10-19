require "test_helper"

class CartCheckoutFlowTest < ActionDispatch::IntegrationTest
  setup do
    @jacket = products(:denim_jacket)
    @jeans = products(:jeans)
  end

  test "thêm sản phẩm vào giỏ rồi xem trên trang giỏ hàng" do
    post cart_items_path, params: { product_id: @jacket.id }
    assert_redirected_to root_path

    get cart_path
    assert_response :success
    assert_select ".cart-line", 1
    assert_select "#cart_summary", /285\.000đ/
  end

  test "thêm vào giỏ bằng turbo_stream trả về các stream cập nhật" do
    post cart_items_path, params: { product_id: @jacket.id }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %r{<turbo-stream action="replace" target="cart_action_product_#{@jacket.id}">}, response.body
    assert_match %r{<turbo-stream action="replace" target="cart_badge">}, response.body
    assert_match "Đã trong giỏ", response.body
  end

  test "cập nhật số lượng và xoá khỏi giỏ" do
    post cart_items_path, params: { product_id: @jacket.id }

    patch cart_item_path(@jacket), params: { quantity: 3 }
    get cart_path
    assert_select ".qty-value", "3"
    assert_select "#cart_summary", /855\.000đ/

    patch cart_item_path(@jacket), params: { quantity: 0 }
    get cart_path
    assert_select ".cart-line", 0
    assert_select ".cart-empty"
  end

  test "xoá sản phẩm khỏi giỏ" do
    post cart_items_path, params: { product_id: @jacket.id }
    delete cart_item_path(@jacket)

    get cart_path
    assert_select ".cart-line", 0
  end

  test "checkout tạo order kèm order_items và dọn sạch giỏ" do
    post cart_items_path, params: { product_id: @jacket.id }
    post cart_items_path, params: { product_id: @jeans.id }
    patch cart_item_path(@jeans), params: { quantity: 2 }

    assert_difference [ "Order.count", "OrderItem.count" ], 0 do
      get cart_path
    end

    assert_difference "Order.count", 1 do
      assert_difference "OrderItem.count", 2 do
        post orders_path, params: {
          order: {
            customer_name: "  Nguyễn Văn A  ",
            phone: "0901 234 567",
            street: "123 Lê Văn Sỹ",
            province_code: 46,
            ward_code: 19753,
            note: "Giao giờ hành chính"
          }
        }
      end
    end

    order = Order.last
    assert_redirected_to order_path(order)

    assert_equal "Nguyễn Văn A", order.customer_name, "customer_name phải được strip"
    assert_equal "0901234567", order.phone, "phone phải bỏ khoảng trắng"
    assert_equal "pending", order.status
    assert_match(/\ANG-\d{6}-[A-Z0-9]{4}\z/, order.code)

    # 285.000 + 220.000 x 2
    assert_equal 725_000, order.total
    assert_equal [ 1, 2 ], order.order_items.order(:id).pluck(:quantity)
    assert_equal [ @jacket.price, @jeans.price ], order.order_items.order(:id).pluck(:price)

    # giỏ đã trống sau khi đặt
    get cart_path
    assert_select ".cart-empty"
  end

  test "checkout thiếu thông tin thì hiện lỗi và giữ nguyên giỏ" do
    post cart_items_path, params: { product_id: @jacket.id }

    assert_no_difference "Order.count" do
      post orders_path, params: { order: { customer_name: "", phone: "abc", street: "" } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
    assert_select ".cart-line", 1
  end

  test "checkout khi giỏ trống thì bị chặn" do
    assert_no_difference "Order.count" do
      post orders_path, params: { order: { customer_name: "A", phone: "0901234567", street: "97 Ngô Đức Kế", province_code: 46, ward_code: 19753 } }
    end

    assert_redirected_to cart_path
    assert_equal "Giỏ hàng đang trống, bạn chọn vài món trước nha.", flash[:alert]
  end

  test "trang xác nhận đơn hiển thị theo mã đơn" do
    post cart_items_path, params: { product_id: @jacket.id }
    post orders_path, params: {
      order: { customer_name: "Trần B", phone: "0912345678", street: "97 Ngô Đức Kế", province_code: 46, ward_code: 19753 }
    }

    order = Order.last
    get order_path(order)

    assert_response :success
    assert_select "h3", text: @jacket.name
    assert_match order.code, response.body
    assert_match "285.000đ", response.body
  end

  test "sản phẩm đã bị xoá khỏi DB thì không làm vỡ giỏ hàng" do
    post cart_items_path, params: { product_id: @jacket.id }
    post cart_items_path, params: { product_id: @jeans.id }
    @jeans.destroy

    get cart_path
    assert_response :success
    assert_select ".cart-line", 1
  end

  test "món đã bán hết không thêm vào giỏ được" do
    @jacket.update!(sold_out: true)

    post cart_items_path, params: { product_id: @jacket.id }

    get cart_path
    assert_select ".cart-line", 0
  end

  test "món trong giỏ vừa bán hết thì không tăng được số lượng và không checkout được" do
    post cart_items_path, params: { product_id: @jacket.id }
    @jacket.update!(sold_out: true)

    patch cart_item_path(@jacket), params: { quantity: 2 }
    get cart_path
    assert_select ".qty-value", "1"
    assert_select ".cart-sold-out"

    assert_no_difference "Order.count" do
      post orders_path, params: { order: { customer_name: "A", phone: "0901234567", street: "1 Lê Lợi",
                                           province_code: 46, ward_code: 19753 } }
    end
    assert_redirected_to cart_path
    assert_match @jacket.name, flash[:alert]

    delete cart_item_path(@jacket)
    get cart_path
    assert_select ".cart-line", 0
  end
end
