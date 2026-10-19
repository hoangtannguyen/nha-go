class BroadcastNewArrivalsJob < ApplicationJob
  queue_as :default

  # Gửi lần lượt từng người, một người lỗi không chặn những người còn lại
  def perform(product_ids, subscriber_ids)
    products = Product.with_attached_photos.includes(:category).where(id: product_ids).to_a
    return if products.empty?

    Subscriber.active.where(id: subscriber_ids).find_each do |subscriber|
      SubscriberMailer.new_arrivals(subscriber, products).deliver_now
      subscriber.record_email_sent!
    rescue StandardError => e
      Rails.logger.error "[BroadcastNewArrivals] Lỗi gửi cho #{subscriber.email}: #{e.message}"
    end
  end
end
