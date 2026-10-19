require "test_helper"

class AdminSubscribersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @owner = admin_users(:owner)
    @active = subscribers(:lan)
    @inactive = subscribers(:huy)
    @jacket = products(:denim_jacket)
    @jeans = products(:jeans)

    post admin_login_path, params: { email: @owner.email, password: "matkhau12345" }
  end

  test "chưa đăng nhập thì không vào được trang thành viên" do
    delete admin_logout_path

    get admin_subscribers_path
    assert_redirected_to admin_login_path
  end

  test "danh sách hiện đủ thành viên và đếm theo trạng thái" do
    get admin_subscribers_path

    assert_response :success
    assert_select "tbody tr", Subscriber.count
    assert_select ".filter-chips .chip", /Đang nhận tin \(#{Subscriber.active.count}\)/
    assert_select ".filter-chips .chip", /Đã huỷ \(#{Subscriber.inactive.count}\)/
  end

  test "lọc theo trạng thái" do
    get admin_subscribers_path(status: "active")
    assert_select "tbody tr", Subscriber.active.count

    get admin_subscribers_path(status: "inactive")
    assert_select "tbody tr", Subscriber.inactive.count
    assert_match @inactive.email, response.body
  end

  test "tìm theo email, tên và số điện thoại" do
    get admin_subscribers_path(q: "lan@")
    assert_select "tbody tr", 1

    get admin_subscribers_path(q: "Văn Nam")
    assert_select "tbody tr", 1

    get admin_subscribers_path(q: "0901234567")
    assert_select "tbody tr", 1
  end

  test "tạm dừng và bật lại nhận tin" do
    patch toggle_admin_subscriber_path(@active)
    assert_response :see_other
    assert_not @active.reload.active?

    patch toggle_admin_subscriber_path(@active)
    assert @active.reload.active?
  end

  test "xoá thành viên khỏi danh sách" do
    assert_difference "Subscriber.count", -1 do
      delete admin_subscriber_path(@active)
    end

    assert_response :see_other
  end

  test "trang gửi email hiện sản phẩm để chọn" do
    get broadcast_admin_subscribers_path

    assert_response :success
    assert_select ".broadcast-item", Product.count
    assert_select "input[name='product_ids[]']", Product.count
    assert_select "input[type=submit][value=?]", "Gửi email cho #{Subscriber.active.count} thành viên"
  end

  test "gửi email xếp job cho đúng người đang nhận tin" do
    assert_enqueued_with job: BroadcastNewArrivalsJob do
      post broadcast_admin_subscribers_path, params: { product_ids: [ @jacket.id, @jeans.id ] }
    end

    assert_redirected_to admin_subscribers_path
    assert_match "2 món", flash[:notice]
    assert_match "#{Subscriber.active.count} thành viên", flash[:notice]

    job = enqueued_jobs.find { |j| j["job_class"] == "BroadcastNewArrivalsJob" }
    recipient_ids = job["arguments"].last
    assert_includes recipient_ids, @active.id
    assert_not_includes recipient_ids, @inactive.id, "người đã huỷ không được gửi"
  end

  test "không chọn sản phẩm nào thì bị chặn" do
    assert_no_enqueued_jobs only: BroadcastNewArrivalsJob do
      post broadcast_admin_subscribers_path, params: { product_ids: [ "" ] }
    end

    assert_redirected_to broadcast_admin_subscribers_path
    assert_match "Chọn ít nhất 1 sản phẩm", flash[:alert]
  end

  test "không còn ai nhận tin thì chặn gửi" do
    Subscriber.update_all(active: false)

    assert_no_enqueued_jobs only: BroadcastNewArrivalsJob do
      post broadcast_admin_subscribers_path, params: { product_ids: [ @jacket.id ] }
    end

    assert_match "Chưa có thành viên nào", flash[:alert]
  end

  test "job gửi mail tới từng người và ghi nhận lần gửi" do
    Subscriber.inactive.destroy_all
    recipients = Subscriber.active.to_a

    assert_emails recipients.size do
      perform_enqueued_jobs do
        BroadcastNewArrivalsJob.perform_later([ @jacket.id ], recipients.map(&:id))
      end
    end

    recipients.each do |subscriber|
      subscriber.reload
      assert_not_nil subscriber.last_emailed_at
      assert subscriber.emails_sent_count.positive?
    end
  end

  test "email hàng mới có nội dung sản phẩm và link huỷ riêng" do
    mail = SubscriberMailer.new_arrivals(@active, [ @jacket ])

    assert_equal [ @active.email ], mail.to
    assert_match @jacket.name, mail.subject

    # phải decode từng part: .body.encoded trả về quoted-printable/base64 nên chữ có dấu không khớp
    html = mail.html_part.decoded
    text = mail.text_part.decoded

    [ html, text ].each do |body|
      assert_match @jacket.name, body
      assert_match price_vnd(@jacket.price), body
      assert_match @active.unsubscribe_token, body, "mỗi người phải có link huỷ riêng"
    end

    assert_match @jacket.category_name, html
  end

  def price_vnd(amount)
    "#{ActiveSupport::NumberHelper.number_to_delimited(amount, delimiter: '.')}đ"
  end

  test "job bỏ qua khi không còn sản phẩm nào" do
    assert_no_emails do
      perform_enqueued_jobs do
        BroadcastNewArrivalsJob.perform_later([ 999_999 ], [ @active.id ])
      end
    end
  end
end
