module ApplicationHelper
  SHOP_PHONE = "0774588154".freeze
  SHOP_PHONE_DISPLAY = "0774 588 154".freeze
  SHOP_FACEBOOK = "https://facebook.com/nhago.thrift".freeze
  SHOP_MAP_URL = "https://www.google.com/maps/place/97+Ng%C3%B4+%C4%90%E1%BB%A9c+K%E1%BA%BF,+Ph%C3%BA+Xu%C3%A2n,+Hu%E1%BA%BF,+Vi%E1%BB%87t+Nam/@16.4780374,107.5825004,17z/data=!3m1!4b1!4m6!3m5!1s0x3141a129185675fb:0x91cbfba11e7877ec!8m2!3d16.4780374!4d107.5825004!16s%2Fg%2F11sgx2lysq".freeze
  # Bản đồ nhúng dạng iframe, không cần API key
  SHOP_MAP_EMBED_URL = "https://www.google.com/maps/embed?origin=mfe&pb=!1m3!2m1!1zOTcgTmfDtCDEkOG7qWMgS-G6vywgUGjDuiBYdcOibiwgSHXhur8!6i17!3m1!1svi!5m1!1svi".freeze

  ORDER_STATUS_LABELS = {
    "pending"   => "Chờ shop xác nhận",
    "confirmed" => "Đã xác nhận",
    "shipped"   => "Đang giao",
    "cancelled" => "Đã huỷ"
  }.freeze

  def zalo_url(message = nil)
    base = "https://zalo.me/#{SHOP_PHONE}"
    message.present? ? "#{base}?msg=#{CGI.escape(message)}" : base
  end

  def price_vnd(amount)
    "#{number_with_delimiter(amount, delimiter: '.')}đ"
  end

  def order_status_label(order)
    ORDER_STATUS_LABELS.fetch(order.status, order.status)
  end

  # Ảnh upload qua admin (Active Storage) được ưu tiên,
  # fallback về file tĩnh trong app/assets/images của dữ liệu seed.
  def product_image_tag(product, **options)
    if product.main_photo
      image_tag product.main_photo, **options
    elsif product.image.present?
      image_tag product.image, **options
    else
      tag.div "👕", class: [ "img-fallback", options[:class] ].compact.join(" ")
    end
  end

  # Logo/banner admin đã upload ở "Cài đặt giao diện", chưa có thì dùng ảnh tĩnh mặc định
  def site_image_tag(name, **options)
    image = site_setting.image(name)

    image_tag image.attached? ? image : SiteSetting::IMAGES.fetch(name.to_s)[:default], **options
  end

  def site_setting
    @site_setting ||= SiteSetting.current
  end
end
