require "test_helper"

class CheckoutAddressTest < ActionDispatch::IntegrationTest
  HUE = 46
  PHU_XUAN = 19753
  HA_NOI = 1

  setup do
    @jacket = products(:denim_jacket)
  end

  # ===== dữ liệu địa giới =====

  test "dữ liệu là đơn vị hành chính 2 cấp sau sáp nhập" do
    assert_equal 34, VietnamAddress.provinces.size, "sau 01/07/2025 còn 34 tỉnh/thành"
    assert_equal 3321, VietnamAddress.data[:ward_count]

    # chỉ 6 thành phố trực thuộc trung ương
    cities = VietnamAddress.provinces.select { |p| p[:type] == "thanh_pho_trung_uong" }
    assert_equal %w[Hà\ Nội Hải\ Phòng Huế Đà\ Nẵng Hồ\ Chí\ Minh Cần\ Thơ].sort,
                 cities.map { |p| p[:short_name] }.sort
  end

  test "3 tỉnh bị API gắn nhầm thành thành phố đã được sửa" do
    [ 22, 24, 75 ].each do |code|
      province = VietnamAddress.province(code)
      assert_equal "tinh", province[:type]
      assert_match(/\ATỉnh /, province[:name], "#{province[:name]} phải là Tỉnh")
    end
  end

  test "không còn cấp quận/huyện" do
    assert_not VietnamAddress.provinces.first.key?(:districts)
    types = VietnamAddress.provinces.flat_map { |p| p[:wards].map { |w| w[:type] } }.uniq
    assert_equal %w[phường xã đặc\ khu].sort, types.sort
  end

  # ===== endpoint phường/xã =====

  test "endpoint trả phường/xã theo tỉnh" do
    get address_wards_path(province_code: HUE)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Thành phố Huế", body["province"]
    assert_equal 40, body["wards"].size
    assert_includes body["wards"].map { |w| w["name"] }, "Phường Phú Xuân"
  end

  test "endpoint với mã tỉnh sai trả rỗng chứ không lỗi" do
    get address_wards_path(province_code: 99_999)

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["province"]
    assert_empty body["wards"]
  end

  # ===== form checkout =====

  test "form checkout có ô chọn tỉnh và phường" do
    post cart_items_path, params: { product_id: @jacket.id }
    get cart_path

    assert_response :success
    assert_select "input[name='order[street]'][required]"
    assert_select "select[name='order[province_code]'] option", 35 # 34 tỉnh + prompt
    assert_select "select[name='order[ward_code]'][disabled]"
    assert_select "[data-controller='address-select'][data-address-select-url-value=?]", address_wards_path
  end

  # ===== đặt hàng =====

  test "đặt hàng ghép địa chỉ đầy đủ từ các trường" do
    post cart_items_path, params: { product_id: @jacket.id }
    post orders_path, params: {
      order: { customer_name: "Khách", phone: "0901234567",
               street: "  97 Ngô Đức Kế  ", province_code: HUE, ward_code: PHU_XUAN }
    }

    order = Order.last
    assert_redirected_to order_path(order)
    assert_equal "97 Ngô Đức Kế", order.street, "street phải được strip"
    assert_equal "Phường Phú Xuân", order.ward_name
    assert_equal "Thành phố Huế", order.province_name
    assert_equal "97 Ngô Đức Kế, Phường Phú Xuân, Thành phố Huế", order.address
  end

  test "thiếu tỉnh hoặc phường thì không đặt được" do
    post cart_items_path, params: { product_id: @jacket.id }

    assert_no_difference "Order.count" do
      post orders_path, params: {
        order: { customer_name: "Khách", phone: "0901234567", street: "97 Ngô Đức Kế" }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors", /tỉnh\/thành/
  end

  test "phường không thuộc tỉnh đã chọn thì bị chặn" do
    post cart_items_path, params: { product_id: @jacket.id }

    assert_no_difference "Order.count" do
      post orders_path, params: {
        order: { customer_name: "Khách", phone: "0901234567", street: "1 Trần Phú",
                 province_code: HA_NOI, ward_code: PHU_XUAN }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors", /không thuộc tỉnh/
  end

  test "mã tỉnh bịa bị chặn" do
    post cart_items_path, params: { product_id: @jacket.id }

    assert_no_difference "Order.count" do
      post orders_path, params: {
        order: { customer_name: "Khách", phone: "0901234567", street: "1 Trần Phú",
                 province_code: 99_999, ward_code: PHU_XUAN }
      }
    end

    assert_response :unprocessable_content
  end

  test "thiếu số nhà thì không đặt được" do
    post cart_items_path, params: { product_id: @jacket.id }

    assert_no_difference "Order.count" do
      post orders_path, params: {
        order: { customer_name: "Khách", phone: "0901234567", street: "",
                 province_code: HUE, ward_code: PHU_XUAN }
      }
    end

    assert_response :unprocessable_content
  end

  test "trang xác nhận và admin hiện địa chỉ đầy đủ" do
    post cart_items_path, params: { product_id: @jacket.id }
    post orders_path, params: {
      order: { customer_name: "Khách", phone: "0901234567",
               street: "97 Ngô Đức Kế", province_code: HUE, ward_code: PHU_XUAN }
    }
    order = Order.last

    get order_path(order)
    assert_match "97 Ngô Đức Kế, Phường Phú Xuân, Thành phố Huế", response.body

    post admin_login_path, params: { email: admin_users(:owner).email, password: "matkhau12345" }
    get admin_order_path(order)
    assert_match "97 Ngô Đức Kế, Phường Phú Xuân, Thành phố Huế", response.body
  end

  test "đơn cũ chỉ có cột address vẫn đọc được" do
    order = Order.new(customer_name: "Khách Cũ", phone: "0901234567",
                      street: "1 Trần Phú", province_code: HUE, ward_code: PHU_XUAN)
    order.order_items.build(product: @jacket, name: @jacket.name, price: @jacket.price, quantity: 1)
    order.recalculate_total
    order.save!

    # giả lập đơn cũ: xoá phần tách nhỏ, chỉ giữ address
    order.update_columns(street: nil, ward_code: nil, ward_name: nil,
                         province_code: nil, province_name: nil,
                         address: "123 Lê Lợi, Quận 1, TP.HCM")

    post admin_login_path, params: { email: admin_users(:owner).email, password: "matkhau12345" }
    get admin_order_path(order.reload)
    assert_response :success
    assert_match "123 Lê Lợi, Quận 1, TP.HCM", response.body
    assert_not order.address_parts?
  end
end
