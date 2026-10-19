require "test_helper"

class GhtkShipmentTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  HUE = 46
  PHU_XUAN = 19753

  GHTK_ENV = {
    "GHTK_API_TOKEN" => "test-token",
    "GHTK_PICK_NAME" => "Nhà Gô",
    "GHTK_PICK_TEL" => "0774588154",
    "GHTK_PICK_ADDRESS" => "1 Lê Lợi",
    "GHTK_PICK_PROVINCE" => "Thành phố Huế",
    "GHTK_PICK_WARD" => "Phường Phú Xuân",
    "GHTK_DEFAULT_ITEM_WEIGHT_KG" => "0.4",
    "GHTK_WEBHOOK_HASH" => "secret-hash"
  }.freeze

  # Thay HTTP thật bằng client giả: ghi lại payload và trả response định sẵn
  class FakeClient
    attr_reader :config, :payloads, :status_calls

    def initialize(create_response: nil, status_response: nil, error: nil)
      @config = Ghtk::Config.new
      @create_response = create_response
      @status_response = status_response
      @error = error
      @payloads = []
      @status_calls = []
    end

    def create_order(payload)
      raise @error if @error

      @payloads << payload
      @create_response
    end

    def order_status(code)
      @status_calls << code
      @status_response
    end
  end

  SUCCESS = {
    "success" => true, "message" => "",
    "order" => { "partner_id" => "x", "label" => "S1.A1.2001297581", "fee" => "30400",
                 "estimated_deliver_time" => "Chiều 2026-10-14", "status_id" => 2 }
  }.freeze

  setup do
    @owner = admin_users(:owner)
    @jacket = products(:denim_jacket)
    @saved_env = GHTK_ENV.keys.index_with { |key| ENV[key] }
    GHTK_ENV.each { |key, value| ENV[key] = value }

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  teardown do
    @saved_env.each { |key, value| ENV[key] = value }
    restore_client
  end

  def create_order(email: "khach@example.com", status: :confirmed)
    order = Order.new(customer_name: "Nguyễn Văn A", phone: "0901234567", email: email, street: "97 Ngô Đức Kế",
                      province_code: HUE, ward_code: PHU_XUAN, note: "Gọi trước", status: status)
    order.order_items.build(product: @jacket, name: @jacket.name, price: @jacket.price, quantity: 2)
    order.recalculate_total
    order.save!
    order
  end

  # Minitest 6 bỏ minitest/mock nên tự ghi đè rồi trả lại, giống order_admin_notification_test
  def use_client(fake)
    Ghtk::Client.define_singleton_method(:new) { |*| fake }
    fake
  end

  def restore_client
    Ghtk::Client.singleton_class.send(:remove_method, :new) if Ghtk::Client.singleton_methods(false).include?(:new)
  end

  def ship(order)
    patch admin_order_path(order), params: { order: { status: "shipped" } }
  end

  # ===== tạo vận đơn =====

  test "chuyển sang Đang giao thì tạo vận đơn GHTK, lưu mã và xếp mail báo khách" do
    fake = use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order

    assert_enqueued_with job: NotifyCustomerOfShipmentJob, args: [ order.id ] do
      ship(order)
    end

    assert_response :see_other
    order.reload
    assert order.shipped?
    assert_equal "ghtk", order.carrier
    assert_equal "S1.A1.2001297581", order.tracking_code
    assert_equal 30_400, order.shipping_fee
    assert_equal 2, order.carrier_status_id
    assert_not_nil order.shipment_created_at
    assert_nil order.shipment_error

    payload = fake.payloads.sole
    assert_equal order.code, payload[:order][:id]
    assert_equal "Nguyễn Văn A", payload[:order][:name]
    assert_equal "0901234567", payload[:order][:tel]
    assert_equal "97 Ngô Đức Kế", payload[:order][:address]
    assert_equal "Thành phố Huế", payload[:order][:province]
    assert_equal "Phường Phú Xuân", payload[:order][:ward]
    assert_equal order.total, payload[:order][:pick_money]
    assert_equal order.total, payload[:order][:value]
    assert_equal 0, payload[:order][:is_freeship]
    assert_equal 0.8, payload[:order][:total_weight]
    assert_equal "Nhà Gô", payload[:order][:pick_name]
    assert_equal [ { name: @jacket.name, weight: 0.4, quantity: 2, price: @jacket.price } ], payload[:products]
  end

  test "GHTK_IS_FREESHIP=1 thì shop trả phí ship" do
    ENV["GHTK_IS_FREESHIP"] = "1"
    fake = use_client(FakeClient.new(create_response: SUCCESS))
    ship(create_order)

    assert_equal 1, fake.payloads.sole[:order][:is_freeship]
  ensure
    ENV.delete("GHTK_IS_FREESHIP")
  end

  test "lưu Đang giao nhiều lần không tạo thêm vận đơn và không xếp thêm mail" do
    fake = use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)

    assert_no_enqueued_jobs only: NotifyCustomerOfShipmentJob do
      ship(order)
    end

    assert_equal 1, fake.payloads.size
  end

  test "đơn đã có vận đơn, huỷ rồi chuyển lại Đang giao thì không gọi GHTK lần nữa" do
    fake = use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)
    patch admin_order_path(order), params: { order: { status: "cancelled" } }
    ship(order)

    assert_equal 1, fake.payloads.size
    assert_equal "S1.A1.2001297581", order.reload.tracking_code
  end

  test "GHTK báo trùng mã đơn thì lấy lại vận đơn cũ thay vì tạo mới" do
    duplicate = {
      "success" => false, "message" => "Mã đơn hàng của bạn đã tồn tại trên hệ thống GHTK",
      "error" => { "code" => "ORDER_ID_EXIST", "ghtk_label" => "S1.A1.1737345",
                   "created" => "2026-10-12T09:18:39+07:00", "status" => 2 }
    }
    use_client(FakeClient.new(create_response: duplicate))
    order = create_order
    ship(order)

    order.reload
    assert order.shipped?
    assert_equal "S1.A1.1737345", order.tracking_code
  end

  test "GHTK từ chối thì giữ trạng thái cũ, báo lỗi cho admin và không báo khách" do
    use_client(FakeClient.new(create_response: { "success" => false, "message" => "Địa chỉ không hợp lệ" }))
    order = create_order

    assert_no_enqueued_jobs only: NotifyCustomerOfShipmentJob do
      ship(order)
    end

    assert_response :unprocessable_content
    assert_match "Địa chỉ không hợp lệ", response.body
    order.reload
    assert order.confirmed?
    assert_nil order.tracking_code
    assert_equal "Địa chỉ không hợp lệ", order.shipment_error
  end

  test "lỗi mạng khi gọi GHTK thì giữ trạng thái cũ" do
    use_client(FakeClient.new(error: Ghtk::Error.new("Không kết nối được GHTK (Net::OpenTimeout)")))
    order = create_order
    ship(order)

    assert_response :unprocessable_content
    assert order.reload.confirmed?
  end

  test "chưa cấu hình token thì không gọi GHTK và không chuyển trạng thái" do
    ENV.delete("GHTK_API_TOKEN")
    order = create_order
    ship(order)

    assert_response :unprocessable_content
    assert_match "GHTK_API_TOKEN", response.body
    assert order.reload.confirmed?
  end

  test "đổi sang trạng thái khác Đang giao không gọi GHTK" do
    fake = use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order(status: :pending)
    patch admin_order_path(order), params: { order: { status: "confirmed" } }

    assert order.reload.confirmed?
    assert_empty fake.payloads
  end

  test "trang admin và trang đơn của khách hiện mã vận đơn và trạng thái giao" do
    use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)

    get admin_order_path(order)
    assert_response :ok
    assert_match "S1.A1.2001297581", response.body
    assert_match "Đã tiếp nhận", response.body

    get order_path(order)
    assert_response :ok
    assert_match "S1.A1.2001297581", response.body
    assert_match "Giao Hàng Tiết Kiệm (GHTK)", response.body
  end

  # ===== email báo khách =====

  test "mail báo khách có mã đơn, mã vận đơn, đơn vị vận chuyển, thời điểm gửi và link tra cứu" do
    use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)
    order.reload

    mail = OrderMailer.shipment_sent(order)
    assert_equal [ "khach@example.com" ], mail.to
    assert_match order.code, mail.subject
    assert_match "S1.A1.2001297581", mail.subject

    [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
      assert_match order.code, body
      assert_match "S1.A1.2001297581", body
      assert_match "Giao Hàng Tiết Kiệm (GHTK)", body
      assert_match I18n.l(order.shipment_created_at, format: :long), body
      assert_match "/orders/#{order.code}", body
      assert_match Ghtk::LOOKUP_URL, body
    end
  end

  test "job chạy nhiều lần chỉ gửi một mail" do
    use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)

    assert_emails 1 do
      2.times { NotifyCustomerOfShipmentJob.perform_now(order.id) }
    end
    assert_not_nil order.reload.shipping_notified_at
  end

  test "đơn không có email thì không gửi mail nhưng vẫn tạo vận đơn" do
    use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order(email: nil)

    assert_no_enqueued_jobs only: NotifyCustomerOfShipmentJob do
      ship(order)
    end
    assert order.reload.shipment?
    assert_no_emails { NotifyCustomerOfShipmentJob.perform_now(order.id) }
  end

  test "đơn chưa có vận đơn thì job không gửi mail" do
    order = create_order
    order.update_columns(status: Order.statuses[:shipped])

    assert_no_emails { NotifyCustomerOfShipmentJob.perform_now(order.id) }
  end

  # ===== webhook =====

  def shipped_order
    use_client(FakeClient.new(create_response: SUCCESS))
    order = create_order
    ship(order)
    order.reload
  end

  def webhook(order, hash: "secret-hash", **attrs)
    post ghtk_webhook_path(hash: hash), params: {
      partner_id: order.code, label_id: order.tracking_code, status_id: 4,
      action_time: "2099-01-01T10:00:00+07:00", reason: "", fee: 30_400
    }.merge(attrs)
  end

  test "webhook sai hash bị từ chối" do
    order = shipped_order
    webhook(order, hash: "sai")

    assert_response :unauthorized
    assert_equal 2, order.reload.carrier_status_id
  end

  test "webhook cập nhật trạng thái giao và thời gian" do
    order = shipped_order
    webhook(order, status_id: 9, reason: "Khách hẹn giao lại")

    assert_response :ok
    order.reload
    assert_equal 9, order.carrier_status_id
    assert_equal "Khách hẹn giao lại", order.carrier_status_reason
    assert_equal Time.zone.parse("2099-01-01T10:00:00+07:00"), order.carrier_status_updated_at
  end

  test "webhook nhận JSON cũng được" do
    order = shipped_order
    post ghtk_webhook_path(hash: "secret-hash"),
         params: { partner_id: order.code, label_id: order.tracking_code, status_id: 5,
                   action_time: "2099-01-01T10:00:00+07:00" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :ok
    assert_equal 5, order.reload.carrier_status_id
  end

  test "webhook tới muộn với thời điểm cũ hơn thì bỏ qua" do
    order = shipped_order
    webhook(order, status_id: 5, action_time: "2099-01-02T10:00:00+07:00")
    webhook(order, status_id: 4, action_time: "2099-01-01T10:00:00+07:00")

    assert_equal 5, order.reload.carrier_status_id
  end

  test "webhook đơn không khớp mã vận đơn thì bỏ qua nhưng vẫn trả 200" do
    order = shipped_order
    webhook(order, label_id: "S1.KHAC")

    assert_response :ok
    assert_equal 2, order.reload.carrier_status_id
  end

  test "webhook thiếu status_id trả 400" do
    order = shipped_order
    webhook(order, status_id: "")

    assert_response :bad_request
  end

  # ===== tra cứu định kỳ =====

  test "job tra cứu cập nhật trạng thái đơn đang giao" do
    order = shipped_order
    fake = use_client(FakeClient.new(status_response: {
      "success" => true, "order" => { "label_id" => order.tracking_code, "status" => "5",
                                      "modified" => "2099-01-03 08:00:00", "ship_money" => 31_000 }
    }))

    SyncShipmentStatusesJob.perform_now

    assert_equal [ order.tracking_code ], fake.status_calls
    order.reload
    assert_equal 5, order.carrier_status_id
    assert_equal 31_000, order.shipping_fee
  end

  test "job tra cứu bỏ qua đơn đã ở trạng thái cuối" do
    order = shipped_order
    order.update_columns(carrier_status_id: 6)
    fake = use_client(FakeClient.new(status_response: { "success" => true, "order" => { "status" => "6" } }))

    SyncShipmentStatusesJob.perform_now

    assert_empty fake.status_calls
  end

  # ===== checkout lưu email =====

  test "checkout lưu email khách nhập, email sai định dạng thì báo lỗi" do
    post cart_items_path, params: { product_id: @jacket.id }
    params = { customer_name: "Nguyễn Văn A", phone: "0901234567", street: "97 Ngô Đức Kế",
               province_code: HUE, ward_code: PHU_XUAN }

    assert_no_difference "Order.count" do
      post orders_path, params: { order: params.merge(email: "khong-hop-le") }
    end
    assert_response :unprocessable_content

    post orders_path, params: { order: params.merge(email: " Khach@Example.com ") }
    assert_equal "khach@example.com", Order.last.email
  end
end
