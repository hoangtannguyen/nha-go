require "test_helper"

class AdminSettingsTest < ActionDispatch::IntegrationTest
  setup do
    post admin_login_path, params: { email: admin_users(:owner).email, password: "matkhau12345" }
  end

  test "chưa đăng nhập thì không vào được trang cài đặt" do
    delete admin_logout_path

    get edit_admin_settings_path
    assert_redirected_to admin_login_path
  end

  test "chưa upload thì trang chủ dùng ảnh tĩnh mặc định" do
    get root_path

    assert_response :success
    assert_select "header .brand img[src*='logo']"
    assert_select ".hero-img img[src*='hero']"
    assert_select ".about img[src*='about']"
  end

  test "upload logo và banner thì trang chủ dùng ảnh mới" do
    patch admin_settings_path, params: { site_setting: {
      logo: fixture_file_upload("product.png", "image/png"),
      hero: fixture_file_upload("product2.webp", "image/webp")
    } }

    assert_redirected_to edit_admin_settings_path
    setting = SiteSetting.first
    assert setting.logo.attached?
    assert setting.hero.attached?
    assert_not setting.about.attached?, "ảnh không chọn thì giữ nguyên"

    get root_path
    assert_select "header .brand img[src*='product.png']"
    assert_select ".hero-img img[src*='product2.webp']"
    assert_select ".about img[src*='about']"
  end

  test "file không phải ảnh bị từ chối" do
    patch admin_settings_path, params: { site_setting: { logo: fixture_file_upload("notes.txt", "text/plain") } }

    assert_response :unprocessable_content
    assert_select ".form-errors", text: /Logo: phải là file ảnh/
    assert_not SiteSetting.first.logo.attached?
  end

  test "chưa sửa thì mục Câu chuyện dùng nội dung mặc định" do
    get root_path

    assert_select ".about .sec-title", text: "Câu chuyện Nhà Gô"
    assert_select ".about .sec-title .hand", text: "Nhà Gô"
    assert_select ".about p:not(.quote)", 3
    assert_select ".about p.quote", text: /Mỗi món đồ si là một cái duyên/
  end

  test "sửa nội dung mục Câu chuyện, mỗi đoạn cách dòng trống thành 1 thẻ p" do
    patch admin_settings_path, params: { site_setting: {
      about_title: "Chuyện của",
      about_title_highlight: "Gô",
      about_body: "Đoạn một.\r\ndòng hai\r\n\r\nĐoạn <b>hai</b>.",
      about_quote: "Trích dẫn mới",
      logo: ""
    } }

    assert_redirected_to edit_admin_settings_path
    assert_not SiteSetting.first.logo.attached?, "ô ảnh để trống không xoá/ghi đè ảnh"

    get root_path
    assert_select ".about .sec-title", text: "Chuyện của Gô"
    assert_select ".about p:not(.quote)", 2
    assert_select ".about p", text: /Đoạn <b>hai<\/b>\./, message: "HTML phải bị escape"
    assert_select ".about p.quote", text: "Trích dẫn mới"
  end

  test "xoá trắng ô thì quay về nội dung mặc định" do
    SiteSetting.instance.update!(about_title: "Tiêu đề cũ")

    patch admin_settings_path, params: { site_setting: { about_title: "   " } }

    assert_nil SiteSetting.first.about_title
    get root_path
    assert_select ".about .sec-title", text: "Câu chuyện Nhà Gô"
  end

  test "nội dung quá dài bị từ chối và giữ lại chữ đã gõ" do
    patch admin_settings_path, params: { site_setting: { about_title: "a" * 61 } }

    assert_response :unprocessable_content
    assert_select ".form-errors", text: /Tiêu đề: tối đa 60 ký tự/
    assert_select "input[name='site_setting[about_title]'][value=?]", "a" * 61
  end

  test "khôi phục ảnh mặc định" do
    SiteSetting.instance.logo.attach(fixture_file_upload("product.png", "image/png"))

    delete reset_image_admin_settings_path("logo")

    assert_redirected_to edit_admin_settings_path
    assert_not SiteSetting.first.logo.attached?
  end

  test "tên ảnh lạ không gọi được method tuỳ ý" do
    delete reset_image_admin_settings_path("destroy")

    assert_redirected_to edit_admin_settings_path
    assert_equal "Không tìm thấy ảnh cần khôi phục.", flash[:alert]
    assert SiteSetting.exists?
  end
end
