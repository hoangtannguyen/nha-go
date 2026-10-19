require "test_helper"

class OrderAdminNotificationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  HUE = 46
  PHU_XUAN = 19753

  setup do
    @jacket = products(:denim_jacket)
    @owner = admin_users(:owner)
    @staff = admin_users(:staff)
    @locked = admin_users(:locked)
  end

  def place_order(note: nil)
    post cart_items_path, params: { product_id: @jacket.id }
    post orders_path, params: {
      order: { customer_name: "Nguyễn Văn A", phone: "0901234567",
               street: "97 Ngô Đức Kế", province_code: HUE, ward_code: PHU_XUAN, note: note }
    }
    Order.last
  end

  test "đặt hàng xong thì xếp job báo admin" do
    assert_enqueued_with job: NotifyAdminsOfOrderJob do
      place_order
    end
  end

  test "gửi mail cho mọi admin đang hoạt động, bỏ qua tài khoản bị khoá" do
    order = place_order

    assert_emails AdminUser.enabled.count do
      perform_enqueued_jobs(only: NotifyAdminsOfOrderJob) do
        NotifyAdminsOfOrderJob.perform_later(order.id)
      end
    end

    recipients = ActionMailer::Base.deliveries.last(AdminUser.enabled.count).flat_map(&:to)
    assert_includes recipients, @owner.email
    assert_includes recipients, @staff.email
    assert_not_includes recipients, @locked.email, "tài khoản bị khoá không nhận mail"
  end

  test "nội dung mail có đủ thông tin đơn" do
    order = place_order(note: "Giao giờ hành chính")
    mail = OrderMailer.new_order(order, @owner)

    assert_equal [ @owner.email ], mail.to
    assert_match order.code, mail.subject
    assert_match "Nguyễn Văn A", mail.subject

    [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
      assert_match order.code, body
      assert_match "Nguyễn Văn A", body
      assert_match "0901234567", body
      assert_match "97 Ngô Đức Kế, Phường Phú Xuân, Thành phố Huế", body
      assert_match "Giao giờ hành chính", body
      assert_match @jacket.name, body
      assert_match "285.000đ", body
      assert_match "/admin/orders/#{order.code}", body, "phải có link mở đơn trong admin"
    end
  end

  test "đơn không ghi chú thì mail không có mục ghi chú" do
    order = place_order
    mail = OrderMailer.new_order(order, @owner)

    assert_no_match(/Ghi chú/, mail.text_part.decoded)
  end

  test "mail nội bộ không dùng footer của người đăng ký nhận tin" do
    order = place_order
    mail = OrderMailer.new_order(order, @owner)

    assert_no_match(/đã đăng ký nhận tin/, mail.html_part.decoded)
    assert_no_match(/Huỷ nhận tin/, mail.html_part.decoded)
  end

  test "job bỏ qua đơn không tồn tại" do
    assert_no_emails do
      perform_enqueued_jobs(only: NotifyAdminsOfOrderJob) do
        NotifyAdminsOfOrderJob.perform_later(999_999)
      end
    end
  end

  test "không còn admin nào hoạt động thì không gửi gì" do
    AdminUser.update_all(active: false)
    order = Order.last || place_order

    assert_no_emails do
      perform_enqueued_jobs(only: NotifyAdminsOfOrderJob) do
        NotifyAdminsOfOrderJob.perform_later(order.id)
      end
    end
  end

  test "mail hỏng không làm hỏng việc đặt hàng" do
    # Minitest 6 bỏ minitest/mock nên tự ghi đè rồi trả lại, không thêm gem chỉ vì 1 test
    NotifyAdminsOfOrderJob.define_singleton_method(:perform_later) { |*| raise "SMTP chết" }

    begin
      assert_difference "Order.count", 1 do
        place_order
      end

      assert_response :see_other
    ensure
      NotifyAdminsOfOrderJob.singleton_class.send(:remove_method, :perform_later)
    end
  end
end
