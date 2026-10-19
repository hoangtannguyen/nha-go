class SubscribersController < ApplicationController
  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(subscriber_params)
    existing = Subscriber.find_by(email: @subscriber.email)

    # Đã đăng ký rồi nhưng từng huỷ thì bật lại, không báo lỗi trùng
    if existing && !existing.active?
      existing.resubscribe!
      send_welcome(existing)
      redirect_to subscriber_thanks_path, status: :see_other
      return
    end

    if @subscriber.save
      send_welcome(@subscriber)
      redirect_to subscriber_thanks_path, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def thanks
  end

  def unsubscribe
    @subscriber = Subscriber.find_by(unsubscribe_token: params[:token])

    return render :unsubscribe_missing, status: :not_found if @subscriber.nil?

    @subscriber.unsubscribe! if @subscriber.active?
  end

  private

  def subscriber_params
    params.expect(subscriber: [ :email, :name, :phone ])
  end

  def send_welcome(subscriber)
    SubscriberMailer.welcome(subscriber).deliver_later
  rescue StandardError => e
    # Chưa cấu hình SMTP thì vẫn cho đăng ký thành công, chỉ ghi log
    Rails.logger.error "[SubscriberMailer] Không gửi được mail chào mừng: #{e.message}"
  end
end
