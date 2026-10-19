require "test_helper"

class ProductCatalogTest < ActionDispatch::IntegrationTest
  setup do
    @jacket = products(:denim_jacket)  # aokhoac, 285_000
    @jeans = products(:jeans)          # quandai, 220_000
  end

  test "trang tất cả sản phẩm hiện đủ món" do
    get products_path

    assert_response :success
    assert_select "h1", /Tất cả/
    assert_select ".card", Product.count
    assert_select ".catalog-count", /#{Product.count}/
  end

  test "trang chủ có nút dẫn sang trang tất cả sản phẩm" do
    get root_path

    assert_response :success
    assert_select ".see-all a[href=?]", products_path, /Xem tất cả #{Product.count} món/
  end

  test "lọc theo danh mục" do
    get products_path(category: "aokhoac")

    assert_response :success
    assert_select ".card", 1
    assert_match @jacket.name, response.body
    assert_no_match(/#{@jeans.name}/, response.body)
    assert_select ".chip.active", /Áo khoác/
  end

  test "chip danh mục hiện số lượng từng loại" do
    get products_path

    assert_select ".chip", Category.count + 1
    assert_select ".chip.active", /Tất cả/
  end

  test "sắp xếp theo giá tăng dần và giảm dần" do
    cheap = Product.create!(name: "Món rẻ", category: categories(:tee), price: 50_000)
    pricey = Product.create!(name: "Món đắt", category: categories(:tee), price: 900_000)

    get products_path(sort: "gia-thap")
    names = css_select(".card h3").map { |node| node.text.strip }
    assert_equal cheap.name, names.first
    assert_equal pricey.name, names.last

    get products_path(sort: "gia-cao")
    names = css_select(".card h3").map { |node| node.text.strip }
    assert_equal pricey.name, names.first
    assert_equal cheap.name, names.last
  end

  test "lọc và sắp xếp dùng được cùng lúc" do
    # fixtures không có món aothun nào nên tự tạo 2 món để kiểm tra thứ tự trong danh mục
    cheap = Product.create!(name: "Áo thun rẻ", category: categories(:tee), price: 50_000)
    pricey = Product.create!(name: "Áo thun đắt", category: categories(:tee), price: 800_000)

    get products_path(category: "aothun", sort: "gia-thap")

    assert_select ".chip.active", /Áo thun/
    assert_select "select[name=sort] option[selected][value='gia-thap']"

    names = css_select(".card h3").map { |node| node.text.strip }
    assert_equal [ cheap.name, pricey.name ], names, "chỉ lấy món aothun và xếp giá tăng dần"
  end

  test "param rác không gây lỗi mà rơi về mặc định" do
    get products_path(category: "khong-co-that", sort: "lung-tung")

    assert_response :success
    assert_select ".card", Product.count
    assert_select ".chip.active", /Tất cả/
    assert_select "select[name=sort] option[selected][value='noi-bat']"
  end

  test "danh mục rỗng hiện trạng thái trống kèm lối thoát" do
    Product.where(category: categories(:shirt)).destroy_all

    get products_path(category: "somiveston")

    assert_response :success
    assert_select ".card", 0
    assert_select ".catalog-empty"
    assert_select ".catalog-empty a[href=?]", products_path
  end

  test "giữ nguyên sort khi bấm sang danh mục khác" do
    get products_path(sort: "gia-cao")

    assert_select ".chips a[href=?]", products_path(category: "aokhoac", sort: "gia-cao")
  end

  test "card trong trang tất cả vẫn vào được chi tiết và thêm giỏ" do
    get products_path

    assert_select "a[href=?]", product_path(@jacket)
    assert_select "form[action=?]", cart_items_path
  end

  test "trang tất cả có tiêu đề và mô tả riêng cho SEO" do
    get products_path
    assert_select "title", /Tất cả sản phẩm/
    assert_select "meta[name=description][content*=?]", "#{Product.count} món"

    get products_path(category: "quandai")
    assert_select "title", /Quần dài/
  end
end
