require "test_helper"

class AdminAuthTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @locked = admin_users(:locked)
  end

  test "chưa đăng nhập thì mọi trang admin đều bị chặn" do
    [ admin_root_path, admin_orders_path, admin_products_path,
      admin_customers_path, admin_admin_users_path ].each do |path|
      get path
      assert_redirected_to admin_login_path, "#{path} phải bị chặn"
    end

    assert_equal "Vui lòng đăng nhập để vào trang quản trị.", flash[:alert]
  end

  test "đăng nhập đúng thì vào được dashboard" do
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }

    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
    assert_select ".admin-nav"
  end

  test "email viết hoa hoặc thừa khoảng trắng vẫn đăng nhập được" do
    post admin_login_path, params: { email: "  OWNER@NhaGo.local  ", password: "matkhau12345" }

    assert_redirected_to admin_root_path
  end

  test "sai mật khẩu thì báo lỗi và không vào được" do
    post admin_login_path, params: { email: @owner.email, password: "saibet" }

    assert_response :unprocessable_content
    assert_equal "Email hoặc mật khẩu không đúng.", flash[:alert]

    get admin_root_path
    assert_redirected_to admin_login_path
  end

  test "tài khoản bị khoá thì không đăng nhập được" do
    post admin_login_path, params: { email: @locked.email, password: "matkhau12345" }

    assert_response :unprocessable_content
    get admin_root_path
    assert_redirected_to admin_login_path
  end

  test "sau khi đăng nhập được đưa về đúng trang đã muốn vào" do
    get admin_products_path
    assert_redirected_to admin_login_path

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
    assert_redirected_to admin_products_path
  end

  test "đăng nhập ghi lại thời điểm last_login_at" do
    assert_nil @owner.last_login_at

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }

    assert_not_nil @owner.reload.last_login_at
  end

  test "đăng xuất thì mất quyền truy cập" do
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
    delete admin_logout_path

    assert_redirected_to admin_login_path
    get admin_root_path
    assert_redirected_to admin_login_path
  end
end
