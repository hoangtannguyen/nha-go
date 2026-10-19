require "test_helper"

class SubscriberSignupTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @active = subscribers(:lan)
    @inactive = subscribers(:huy)
  end

  test "header có nút dẫn sang trang đăng ký" do
    get root_path

    assert_response :success
    assert_select "header a[href=?]", new_subscriber_path
  end

  test "trang đăng ký hiện form" do
    get new_subscriber_path

    assert_response :success
    assert_select "form[action=?]", subscribers_path do
      assert_select "input[name='subscriber[email]'][required]"
      assert_select "input[name='subscriber[name]']"
      assert_select "input[name='subscriber[phone]']"
    end
  end

  test "đăng ký thành công và nhận mail chào mừng" do
    assert_difference "Subscriber.count", 1 do
      assert_enqueued_email_with SubscriberMailer, :welcome, args: ->(args) { args.first.email == "moi@example.com" } do
        post subscribers_path, params: { subscriber: { email: "  MOI@Example.com ", name: "  Khách Mới  " } }
      end
    end

    assert_redirected_to subscriber_thanks_path

    subscriber = Subscriber.find_by(email: "moi@example.com")
    assert_equal "Khách Mới", subscriber.name, "tên phải được strip"
    assert subscriber.active?
    assert subscriber.unsubscribe_token.present?
    assert_not_nil subscriber.subscribed_at
  end

  test "email sai định dạng bị từ chối" do
    assert_no_difference "Subscriber.count" do
      post subscribers_path, params: { subscriber: { email: "khong-phai-email" } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors"
  end

  test "email trùng của người đang nhận tin bị báo lỗi" do
    assert_no_difference "Subscriber.count" do
      post subscribers_path, params: { subscriber: { email: @active.email } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors", /đã đăng ký rồi/
  end

  test "người đã huỷ đăng ký lại thì được bật lại chứ không báo trùng" do
    assert_no_difference "Subscriber.count" do
      post subscribers_path, params: { subscriber: { email: @inactive.email } }
    end

    assert_redirected_to subscriber_thanks_path
    @inactive.reload
    assert @inactive.active?
    assert_nil @inactive.unsubscribed_at
  end

  test "số điện thoại sai định dạng bị từ chối" do
    assert_no_difference "Subscriber.count" do
      post subscribers_path, params: { subscriber: { email: "ok@example.com", phone: "abc" } }
    end

    assert_response :unprocessable_content
  end

  test "trang cảm ơn hiện được" do
    get subscriber_thanks_path

    assert_response :success
    assert_select "h1", /Xong rồi/
  end

  test "huỷ nhận tin bằng token trong email" do
    get unsubscribe_path(token: @active.unsubscribe_token)

    assert_response :success
    assert_select "h1", /Đã huỷ nhận tin/
    @active.reload
    assert_not @active.active?
    assert_not_nil @active.unsubscribed_at
  end

  test "token sai thì báo link hết hiệu lực chứ không nổ lỗi" do
    get unsubscribe_path(token: "token-bay-ba")

    assert_response :not_found
    assert_select "h1", /Link không còn hiệu lực/
  end

  test "huỷ hai lần không làm hỏng gì" do
    get unsubscribe_path(token: @active.unsubscribe_token)
    first_time = @active.reload.unsubscribed_at

    get unsubscribe_path(token: @active.unsubscribe_token)

    assert_response :success
    assert_equal first_time, @active.reload.unsubscribed_at, "không ghi đè thời điểm huỷ"
  end
end
