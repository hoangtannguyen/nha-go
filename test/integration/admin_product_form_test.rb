require "test_helper"

class AdminProductFormTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @jeans = products(:jeans)

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  # ===== giá có dấu phân cách =====

  test "giá nhập dạng 285.000 được lưu thành 285000" do
    post admin_products_path, params: { product: base_attributes(price: "285.000") }

    assert_equal 285_000, Product.find_by(name: "Áo mới").price
  end

  test "các kiểu phân cách khác cũng được bóc đúng" do
    {
      "1.250.000" => 1_250_000,
      "1,250,000" => 1_250_000,
      "1 250 000" => 1_250_000,
      "99.000đ"   => 99_000,
      "450000"    => 450_000
    }.each do |input, expected|
      product = Product.create!(name: "tạm", price: 0, category: categories(:tee))
      patch admin_product_path(product), params: { product: { price: input } }

      assert_equal expected, product.reload.price, "nhập #{input.inspect} phải ra #{expected}"
      product.destroy
    end
  end

  test "giá rỗng không bị hiểu thành 0 ngầm" do
    post admin_products_path, params: { product: base_attributes(price: "") }

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "form edit hiện lại giá đã có dấu phân cách" do
    @jeans.update!(price: 1_250_000)

    get edit_admin_product_path(@jeans)

    assert_response :success
    assert_select "input[name='product[price]'][value='1.250.000']"
  end

  # ===== nhiều màu, nhiều size =====

  test "lưu được nhiều màu và nhiều size" do
    post admin_products_path, params: {
      product: base_attributes(colors: [ "", "den", "trang", "xanh_reu" ], sizes: [ "", "M", "L", "XL" ])
    }

    product = Product.find_by(name: "Áo mới")
    assert_equal %w[den trang xanh_reu], product.colors
    assert_equal %w[M L XL], product.sizes
    assert_equal [ "Đen", "Trắng", "Xanh rêu" ], product.color_names
  end

  test "bỏ chọn hết màu và size thì lưu về mảng rỗng" do
    @jeans.update!(colors: %w[den], sizes: %w[M])

    patch admin_product_path(@jeans), params: { product: { colors: [ "" ], sizes: [ "" ] } }

    @jeans.reload
    assert_empty @jeans.colors
    assert_empty @jeans.sizes
  end

  test "giá trị màu hoặc size lạ bị từ chối" do
    post admin_products_path, params: { product: base_attributes(colors: [ "mau_la" ]) }
    assert_response :unprocessable_content

    post admin_products_path, params: { product: base_attributes(sizes: [ "XXXL" ]) }
    assert_response :unprocessable_content
  end

  test "chọn trùng thì chỉ lưu một lần" do
    post admin_products_path, params: { product: base_attributes(colors: %w[den den trang]) }

    assert_equal %w[den trang], Product.find_by(name: "Áo mới").colors
  end

  test "ô chọn ảnh có đủ hook để xem trước ảnh vừa chọn" do
    get new_admin_product_path

    assert_select "[data-controller='photo-preview']" do
      assert_select "input[type=file][multiple][data-photo-preview-target='input']"
      assert_select "[data-photo-preview-target='list']"
      assert_select "[data-photo-preview-target='warning']"
    end
    assert_select "[data-photo-preview-max-value=?]", Product::MAX_PHOTOS.to_s
    assert_select "[data-photo-preview-existing-value='0']"
  end

  test "form edit báo đúng số ảnh đang có cho phần xem trước" do
    @jeans.photos.attach(fixture_file_upload("product.png", "image/png"))
    @jeans.photos.attach(fixture_file_upload("product2.webp", "image/webp"))

    get edit_admin_product_path(@jeans)

    assert_select "[data-photo-preview-existing-value='2']"
  end

  test "form new và edit hiện đủ ô chọn màu và size" do
    get new_admin_product_path
    assert_response :success
    assert_select "input[name='product[colors][]'][type=checkbox]", Product::COLOR_OPTIONS.size
    assert_select "input[name='product[sizes][]'][type=checkbox]", Product::ALL_SIZES.size

    @jeans.update!(colors: %w[den], sizes: %w[30])
    get edit_admin_product_path(@jeans)
    assert_select "input[name='product[colors][]'][value=den][checked]"
    assert_select "input[name='product[sizes][]'][value='30'][checked]"
  end

  # ===== hiển thị ngoài storefront =====

  test "trang bán hàng hiện size và màu đã chọn" do
    @jeans.update!(colors: %w[xanh_navy trang], sizes: %w[29 30])

    get root_path

    assert_response :success
    assert_match "Size 29, 30", response.body
    assert_match "Xanh navy, Trắng", response.body
  end

  test "sản phẩm chưa chọn size vẫn dùng mô tả size cũ" do
    product = products(:denim_jacket)
    assert_empty product.sizes

    get root_path
    assert_match product.size_label, response.body
  end

  # ===== đã bán hết =====

  test "tích và bỏ tích đã bán hết từ form edit" do
    get edit_admin_product_path(@jeans)
    assert_select "input[type=checkbox][name='product[sold_out]']"

    patch admin_product_path(@jeans), params: { product: { sold_out: "1" } }
    assert @jeans.reload.sold_out?

    get admin_products_path
    assert_select ".admin-table .status-badge.st-cancelled", "Đã bán hết"

    patch admin_product_path(@jeans), params: { product: { sold_out: "0" } }
    assert_not @jeans.reload.sold_out?
  end

  test "món đã bán hết hiện nhãn, ẩn nút mua và xếp cuối ngoài storefront" do
    jacket = products(:denim_jacket)
    jacket.update!(sold_out: true)

    get root_path
    assert_select "article.card.is-sold-out", 1
    assert_select "article.card.is-sold-out .sold-badge", "Đã bán hết"
    assert_select "article.card.is-sold-out a.buy", 0
    assert_select "article.card.is-sold-out button.add-cart", 0
    assert_select "article.card:last-of-type h3", jacket.name

    get product_path(jacket)
    assert_select ".pdp-main .sold-badge", "Đã bán hết"
    assert_select ".pdp-actions a.btn-rust", 0
  end

  test "ô ẩn chỉ hiện khi đã bán hết" do
    get edit_admin_product_path(@jeans)
    assert_select "[data-reveal-toggle-target=panel][hidden] input[name='product[hidden]'][type=checkbox]"

    @jeans.update!(sold_out: true)
    get edit_admin_product_path(@jeans)
    assert_select "[data-reveal-toggle-target=panel]:not([hidden])"
  end

  test "món đã bán hết và ẩn thì biến mất khỏi storefront, link cũ trả 404" do
    patch admin_product_path(@jeans), params: { product: { sold_out: "1", hidden: "1" } }
    assert @jeans.reload.hidden?

    get admin_products_path
    assert_select ".admin-table .status-badge", "Đã ẩn"

    get root_path
    assert_no_match @jeans.name, response.body
    get products_path
    assert_no_match @jeans.name, response.body

    get product_path(@jeans)
    assert_response :not_found
  end

  test "không tích bán hết thì không ẩn được, bỏ tích bán hết thì tự hiện lại" do
    patch admin_product_path(@jeans), params: { product: { hidden: "1" } }
    assert_not @jeans.reload.hidden?

    @jeans.update!(sold_out: true, hidden: true)
    patch admin_product_path(@jeans), params: { product: { sold_out: "0" } }
    assert_not @jeans.reload.hidden?

    get root_path
    assert_match @jeans.name, response.body
  end

  private

  def base_attributes(overrides = {})
    { name: "Áo mới", category_id: categories(:tee).id, price: "150.000", position: 10 }.merge(overrides)
  end
end
