module ApplicationHelper
  SHOP_PHONE = "0774588154".freeze
  SHOP_PHONE_DISPLAY = "0774 588 154".freeze
  SHOP_FACEBOOK = "https://facebook.com/nhago.thrift".freeze

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
