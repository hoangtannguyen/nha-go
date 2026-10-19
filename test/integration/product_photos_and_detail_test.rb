require "test_helper"

class ProductPhotosAndDetailTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @jacket = products(:denim_jacket)
    @jeans = products(:jeans)
  end

  # ===== upload nhiều ảnh =====

  test "tạo sản phẩm với nhiều ảnh một lúc" do
    login

    post admin_products_path, params: {
      product: {
        name: "Áo nhiều ảnh", category_id: categories(:tee).id, price: "320.000",
        photos: [ upload("product.png"), upload("product2.webp", "image/webp"), upload("product3.webp", "image/webp") ]
      }
    }

    product = Product.find_by(name: "Áo nhiều ảnh")
    assert_redirected_to admin_products_path
    assert_equal 3, product.photos.size
  end

  test "upload thêm ảnh thì BỔ SUNG chứ không ghi đè ảnh cũ" do
    login
    @jeans.photos.attach(upload("product.png"))
    assert_equal 1, @jeans.photos.size

    patch admin_product_path(@jeans), params: {
      product: { photos: [ upload("product2.webp", "image/webp") ] }
    }

    assert_equal 2, @jeans.reload.photos.size
  end

  test "sửa sản phẩm mà không chọn ảnh thì giữ nguyên ảnh cũ" do
    login
    @jeans.photos.attach(upload("product.png"))

    patch admin_product_path(@jeans), params: { product: { name: "Quần jeans mới", photos: [ "" ] } }

    @jeans.reload
    assert_equal "Quần jeans mới", @jeans.name
    assert_equal 1, @jeans.photos.size
  end

  test "một file sai định dạng làm hỏng cả lần upload" do
    login

    assert_no_difference "Product.count" do
      post admin_products_path, params: {
        product: { name: "Lẫn file lạ", category_id: categories(:tee).id, price: "100.000",
                   photos: [ upload("product.png"), upload("notes.txt", "text/plain") ] }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "vượt quá số ảnh tối đa bị chặn" do
    login
    Product::MAX_PHOTOS.times { @jeans.photos.attach(upload("product.png")) }

    patch admin_product_path(@jeans), params: { product: { photos: [ upload("product2.webp", "image/webp") ] } }

    assert_response :unprocessable_content
    assert_equal Product::MAX_PHOTOS, @jeans.reload.photos.size
  end

  test "xoá từng ảnh riêng lẻ" do
    login
    @jeans.photos.attach(upload("product.png"))
    @jeans.photos.attach(upload("product2.webp", "image/webp"))
    target = @jeans.photos.first

    assert_difference -> { @jeans.reload.photos.size }, -1 do
      delete admin_product_photo_path(@jeans, target)
    end

    assert_redirected_to edit_admin_product_path(@jeans)
  end

  # button_to sinh <form> lồng trong form_with; thẻ </form> của nó đóng luôn form cha
  # khiến nút submit rơi ra ngoài -> lần sửa thứ 2 (khi đã có ảnh) bấm Lưu không ăn.
  test "form sửa sản phẩm không được chứa form lồng khi đã có ảnh" do
    login
    @jeans.photos.attach(upload("product.png"))
    @jeans.photos.attach(upload("product2.webp", "image/webp"))

    get edit_admin_product_path(@jeans)
    assert_response :success

    form_html = response.body[/<form[^>]*action="#{Regexp.escape(admin_product_path(@jeans))}".*?<\/form>/m]
    assert_not_nil form_html, "không tìm thấy form sửa sản phẩm"
    assert_no_match %r{<form}, form_html.sub(/\A<form[^>]*>/, ""),
                    "form sửa sản phẩm không được chứa <form> lồng bên trong"

    # nút Xoá ảnh phải là link dùng turbo-method, không phải button_to
    assert_select "a.photo-remove[data-turbo-method='delete']", 2
    assert_select ".photo-item form", 0
  end

  test "nút Lưu thay đổi nằm trong form sửa sản phẩm" do
    login
    @jeans.photos.attach(upload("product.png"))

    get edit_admin_product_path(@jeans)

    assert_select "form[action=?]", admin_product_path(@jeans) do
      assert_select "input[type=submit][value='Lưu thay đổi']", 1
      assert_select "input[type=file][name='product[photos][]']", 1
    end
  end

  test "sửa sản phẩm nhiều lần liên tiếp khi đã có ảnh" do
    login

    3.times do |index|
      patch admin_product_path(@jeans), params: {
        product: { name: "Tên lần #{index + 1}", photos: [ upload("product.png") ] }
      }

      assert_response :see_other, "lần sửa #{index + 1} phải thành công"
      assert_equal "Tên lần #{index + 1}", @jeans.reload.name
    end

    assert_equal 3, @jeans.photos.size
  end

  test "form edit hiện lưới ảnh kèm nút xoá" do
    login
    @jeans.photos.attach(upload("product.png"))
    @jeans.photos.attach(upload("product2.webp", "image/webp"))

    get edit_admin_product_path(@jeans)

    assert_response :success
    assert_select ".photo-item", 2
    assert_select ".photo-badge", 1, "chỉ ảnh đầu tiên được đánh dấu đại diện"
    assert_select "input[name='product[photos][]'][multiple]"
  end

  # ===== trang chi tiết =====

  test "trang chi tiết hiện đủ thông tin sản phẩm" do
    @jacket.update!(colors: %w[den xanh_navy], sizes: %w[M L])

    get product_path(@jacket)

    assert_response :success
    assert_select "h1", @jacket.name
    assert_select ".pdp-price", /285\.000đ/
    assert_match "Đen", response.body
    assert_match "Xanh navy", response.body
    assert_select ".pdp-opt", 4 # 2 size + 2 màu
  end

  test "trang chi tiết hiện thumbnail khi có nhiều ảnh" do
    @jacket.photos.attach(upload("product.png"))
    @jacket.photos.attach(upload("product2.webp", "image/webp"))

    get product_path(@jacket)

    assert_select ".pdp-thumb", 2
    assert_select ".pdp-thumb.is-active", 1
  end

  test "chỉ một ảnh thì không hiện dãy thumbnail" do
    @jacket.photos.attach(upload("product.png"))

    get product_path(@jacket)

    assert_select ".pdp-thumb", 0
  end

  test "thêm vào giỏ ngay từ trang chi tiết" do
    get product_path(@jacket)
    assert_select "form[action=?]", cart_items_path

    post cart_items_path, params: { product_id: @jacket.id }
    get cart_path
    assert_select ".cart-line", 1
  end

  test "trang chi tiết gợi ý món cùng danh mục" do
    same = Product.create!(name: "Áo khoác bò", category: categories(:jacket), price: 300_000)
    Product.create!(name: "Quần kaki", category: categories(:pants), price: 200_000)

    get product_path(@jacket)

    assert_select ".pdp-related .card", 1
    assert_match same.name, response.body
  end

  test "card ngoài danh sách link sang trang chi tiết và hiện số ảnh" do
    @jacket.photos.attach(upload("product.png"))
    @jacket.photos.attach(upload("product2.webp", "image/webp"))

    get root_path

    assert_select "a[href=?]", product_path(@jacket)
    assert_select ".photo-count", /2/
  end

  test "sản phẩm không tồn tại trả 404" do
    get product_path(id: 999_999)

    assert_response :not_found
  end

  private

  def login
    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  def upload(name, type = "image/png")
    fixture_file_upload(name, type)
  end
end
