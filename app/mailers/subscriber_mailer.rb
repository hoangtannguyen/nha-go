class SubscriberMailer < ApplicationMailer
  def welcome(subscriber)
    @subscriber = subscriber
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)

    mail to: subscriber.email, subject: "Chào #{subscriber.display_name}, Nhà Gô sẽ báo bạn khi có hàng mới 👕"
  end

  def new_arrivals(subscriber, products)
    @subscriber = subscriber
    @products = products
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)

    subject = if products.size == 1
      "Nhà Gô vừa về: #{products.first.name}"
    else
      "Nhà Gô vừa về #{products.size} món mới 👕"
    end

    mail to: subscriber.email, subject: subject
  end
end
