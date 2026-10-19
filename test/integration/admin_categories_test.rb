require "test_helper"

class AdminCategoriesTest < ActionDispatch::IntegrationTest
  setup do
    @owner = admin_users(:owner)
    @jacket = categories(:jacket)
    @empty_category = categories(:shirt) # fixtures không có sản phẩm nào thuộc danh mục này

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  test "chưa đăng nhập thì không vào được trang danh mục" do
    delete admin_logout_path

    get admin_categories_path
    assert_redirected_to admin_login_path
  end

  test "danh sách hiện đủ danh mục kèm số sản phẩm" do
    get admin_categories_path

    assert_response :success
    assert_select "tbody tr", Category.count
    # relation có group() nên .size trả Hash — phải in ra con số, không phải hash
    assert_select ".toolbar .muted", text: "#{Category.count} danh mục"
    assert_select "td code", text: "aokhoac"
    # fixtures: 1 áo khoác, 1 quần dài
    assert_select "tbody tr", text: /Áo khoác.*aokhoac.*1/
  end

  test "tạo danh mục mới và tự sinh slug từ tên tiếng Việt" do
    assert_difference "Category.count", 1 do
      post admin_categories_path, params: { category: { name: "Giày & Dép", description: "Sneaker, sandal" } }
    end

    assert_response :see_other
    category = Category.find_by(name: "Giày & Dép")
    assert_equal "giay-dep", category.slug, "slug phải bỏ dấu và ký tự đặc biệt"
    assert_equal Category.maximum(:position), category.position, "tự xếp xuống cuối"
  end

  test "tự nhập slug thì dùng slug đó" do
    post admin_categories_path, params: { category: { name: "Phụ kiện", slug: "phu-kien-hot" } }

    assert_equal "phu-kien-hot", Category.find_by(name: "Phụ kiện").slug
  end

  test "slug sai định dạng bị từ chối" do
    assert_no_difference "Category.count" do
      post admin_categories_path, params: { category: { name: "Sai slug", slug: "Slug Có Dấu Cách" } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "tên hoặc slug trùng bị từ chối" do
    assert_no_difference "Category.count" do
      post admin_categories_path, params: { category: { name: @jacket.name } }
    end
    assert_response :unprocessable_content

    assert_no_difference "Category.count" do
      post admin_categories_path, params: { category: { name: "Tên khác", slug: @jacket.slug } }
    end
    assert_response :unprocessable_content
  end

  test "sửa tên và thứ tự danh mục" do
    patch admin_category_path(@jacket), params: {
      category: { name: "Áo khoác & Vest", slug: @jacket.slug, position: 9 }
    }

    assert_response :see_other
    @jacket.reload
    assert_equal "Áo khoác & Vest", @jacket.name
    assert_equal 9, @jacket.position
    assert_equal "aokhoac", @jacket.slug, "giữ nguyên slug thì link cũ không chết"
  end

  test "không xoá được danh mục còn sản phẩm" do
    assert_no_difference "Category.count" do
      delete admin_category_path(@jacket)
    end

    assert_response :see_other
    assert_match "Không xoá được", flash[:alert]
  end

  test "xoá được danh mục rỗng" do
    assert_difference "Category.count", -1 do
      delete admin_category_path(@empty_category)
    end

    assert_match "Đã xoá danh mục", flash[:notice]
  end

  test "thứ tự danh mục quyết định thứ tự chip ngoài trang bán hàng" do
    @jacket.update!(position: 99)

    get products_path
    chips = css_select(".chips .chip").map { |node| node.text.strip }

    assert_equal "Áo khoác", chips.last.split.first(2).join(" ")
  end

  test "form sản phẩm hiện danh mục lấy từ bảng categories" do
    Category.create!(name: "Danh mục mới toanh", position: 50)

    get new_admin_product_path

    assert_response :success
    assert_select "select[name='product[category_id]'] option", Category.count + 1 # +1 cho prompt
    assert_select "select[name='product[category_id]'] option", text: "Danh mục mới toanh"
  end

  test "đổi danh mục của sản phẩm trong admin" do
    product = products(:denim_jacket)

    patch admin_product_path(product), params: { product: { category_id: categories(:pants).id } }

    assert_response :see_other
    assert_equal categories(:pants), product.reload.category
  end
end
