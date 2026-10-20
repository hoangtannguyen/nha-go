require "test_helper"

class PageViewTrackingTest < ActionDispatch::IntegrationTest
  setup do
    @jacket = products(:denim_jacket)
    @owner = admin_users(:owner)
  end

  test "mỗi lần tải trang (kể cả F5) ghi thêm 1 lượt xem" do
    assert_difference "PageView.count", 2 do
      get root_path
      get root_path
    end

    assert_equal [ root_path ], PageView.distinct.pluck(:path)
  end

  test "cùng trình duyệt thì cùng visitor_id, trình duyệt khác thì khác" do
    get root_path
    get products_path
    assert_equal 1, PageView.distinct.count(:visitor_id)

    open_session { |other| other.get root_path }
    assert_equal 2, PageView.distinct.count(:visitor_id)
  end

  test "xem chi tiết sản phẩm thì gắn product vào lượt xem" do
    get product_path(@jacket)

    assert_equal @jacket, PageView.last.product
  end

  test "không tính Turbo prefetch và request không phải HTML" do
    assert_no_difference "PageView.count" do
      get root_path, headers: { "X-Sec-Purpose" => "prefetch" }
      get product_path(@jacket), headers: { "Accept" => "application/json" }
    end
  end

  test "admin đăng nhập thì không tính lượt xem, kể cả trang khách" do
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }

    assert_no_difference "PageView.count" do
      get root_path
      get product_path(@jacket)
      get admin_root_path
    end
  end

  test "trang đăng nhập admin không bị tính" do
    assert_no_difference "PageView.count" do
      get admin_login_path
    end
  end

  test "dashboard hiển thị thống kê lượt xem và top sản phẩm" do
    get product_path(@jacket)
    get product_path(@jacket)
    open_session { |other| other.get root_path }

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
    get admin_root_path

    assert_response :success
    assert_select ".stat-card", text: /Tổng lượt xem trang\s*3/
    assert_select ".stat-card", text: /Khách truy cập \(ước tính\)\s*2/
    assert_select ".stat-card", text: /Lượt xem hôm nay\s*3/
    assert_select ".stat-card", text: /Lượt xem 7 ngày gần nhất\s*3/
    assert_select ".rank-list li", text: /#{@jacket.name}\s*2 lượt/
  end
end
