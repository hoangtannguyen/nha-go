require "test_helper"

class AdminOrderDestroyTest < ActionDispatch::IntegrationTest
  HUE = 46
  PHU_XUAN = 19753

  setup do
    @owner = admin_users(:owner)
    @jacket = products(:denim_jacket)

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  def create_order(phone: "0901234567")
    order = Order.new(customer_name: "Spam Bot", phone: phone, street: "1 Không Có",
                      province_code: HUE, ward_code: PHU_XUAN)
    order.order_items.build(product: @jacket, name: @jacket.name, price: @jacket.price, quantity: 1)
    order.recalculate_total
    order.save!
    order
  end

  test "chưa đăng nhập thì không xoá được đơn" do
    order = create_order
    delete admin_logout_path

    assert_no_difference "Order.count" do
      delete admin_order_path(order)
    end
    assert_redirected_to admin_login_path
  end

  test "xoá đơn spam xoá luôn món trong đơn và khách chỉ có mỗi đơn đó" do
    order = create_order

    assert_difference [ "Order.count", "Customer.count" ], -1 do
      assert_difference "OrderItem.count", -1 do
        delete admin_order_path(order)
      end
    end
    assert_response :see_other
    assert_redirected_to admin_orders_path
  end

  test "khách còn đơn khác thì chỉ xoá đơn, giữ khách" do
    keep = create_order
    spam = create_order

    assert_difference "Order.count", -1 do
      assert_no_difference "Customer.count" do
        delete admin_order_path(spam)
      end
    end
    assert Customer.exists?(keep.customer_id)
  end

  test "đơn đã có vận đơn GHTK thì không xoá được" do
    order = create_order
    order.update_columns(tracking_code: "S1.A1.123")

    assert_no_difference "Order.count" do
      delete admin_order_path(order)
    end
    assert_redirected_to admin_order_path(order)
    assert_match "vận đơn GHTK", flash[:alert]
  end

  test "danh sách đơn có nút Xoá, trừ đơn đã có vận đơn" do
    create_order
    shipped = create_order(phone: "0909999999")
    shipped.update_columns(tracking_code: "S1.A1.456")

    get admin_orders_path

    assert_select "tbody tr", 2
    assert_select "tbody tr button", text: "Xoá", count: 1
  end
end
