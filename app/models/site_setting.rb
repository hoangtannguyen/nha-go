# Ảnh dùng chung toàn site (logo, banner trang chủ) do admin tự thay.
# Chưa upload thì dùng ảnh tĩnh mặc định trong app/assets/images.
class SiteSetting < ApplicationRecord
  IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  IMAGES = {
    "logo"  => { label: "Logo", default: "logo.webp",
                 hint: "Hiện ở header trang bán hàng, trang quản trị và trang đăng nhập. Nên dùng PNG/WEBP nền trong suốt." },
    "hero"  => { label: "Ảnh banner trang chủ", default: "hero.webp",
                 hint: "Ảnh lớn ở đầu trang chủ." },
    "about" => { label: "Ảnh mục \"Câu chuyện Nhà Gô\"", default: "about.webp",
                 hint: "Ảnh cạnh đoạn giới thiệu shop trên trang chủ." }
  }.freeze

  # Chữ trên trang chủ: đoạn giới thiệu ở banner và mục "Câu chuyện Nhà Gô"
  TEXTS = {
    "hero_lead" => {
      label: "Đoạn giới thiệu dưới tiêu đề banner", max: 300,
      default: "Nhà Gô tuyển từng chiếc áo, từng cái quần từ những lô đồ si Nhật – Hàn - Châu Âu uy tín. Rửa sạch, lận phẳng, up lại như mới — bạn chỉ việc mặc."
    },
    "about_title" => { label: "Tiêu đề", max: 60, default: "Câu chuyện" },
    "about_title_highlight" => { label: "Chữ viết tay nổi bật sau tiêu đề", max: 40, default: "Nhà Gô" },
    "about_body" => {
      label: "Nội dung", max: 3000,
      default: <<~TEXT.strip
        Hành trình của Nhà Gô bắt đầu từ những năm 2010, với những lô hàng nhỏ lẻ từng chiếc áo, chiếc quần giữa lòng chợ xép Ngô Đức Kế (TP. Huế). Nơi ấy gói gọn niềm tin giản dị: quần áo cũ chưa hề cũ — chỉ cần gặp đúng người.

        Hơn một thập kỷ trôi qua, mỗi tuần shop vẫn miệt mài tuyển chọn từng món đồ si Nhật, Hàn, Châu Âu chất lượng: hàng chuẩn tuyển, ít giặt, giữ trọn form dáng. Tất cả đều được giặt sạch, hấp phẳng và chụp thật tỉ mỉ trước khi gửi đến bạn.

        Mỗi tuần shop tuyển từ những lô đồ si đã qua kiểm định: form đẹp. Giặt sạch, hấp phẳng, chụp như thật trước khi lên web.
      TEXT
    },
    "about_quote" => { label: "Câu trích dẫn", max: 200,
                       default: "\"Mỗi món đồ si là một cái duyên — chỉ chờ đúng người nhận ra giá trị.\"" }
  }.freeze

  has_one_attached :logo
  has_one_attached :hero
  has_one_attached :about

  validate :images_must_be_valid
  validate :texts_within_limits

  normalizes(*TEXTS.keys.map(&:to_sym), with: ->(value) { value.to_s.strip.presence })

  # Dùng khi hiển thị: không ghi DB lúc khách xem trang
  def self.current
    first || new
  end

  # Dùng ở admin: cần bản ghi thật để gắn ảnh
  def self.instance
    first || create!
  end

  def image(name)
    raise ArgumentError, "unknown site image: #{name}" unless IMAGES.key?(name.to_s)

    public_send(name)
  end

  # Để trống thì dùng nội dung mặc định
  def text(name)
    self[name].presence || TEXTS.fetch(name.to_s)[:default]
  end

  # Mỗi đoạn cách nhau bằng 1 dòng trống
  def about_paragraphs
    text("about_body").split(/\r?\n\s*\r?\n/).map(&:strip).reject(&:blank?)
  end

  private

  def texts_within_limits
    TEXTS.each do |name, config|
      value = self[name]
      next if value.blank? || value.length <= config[:max]

      errors.add(:base, "#{config[:label]}: tối đa #{config[:max]} ký tự (đang có #{value.length})")
    end
  end

  def images_must_be_valid
    IMAGES.each do |name, config|
      file = public_send(name)
      next unless file.attached?

      unless file.content_type.in?(IMAGE_TYPES)
        errors.add(:base, "#{config[:label]}: phải là file ảnh (JPG, PNG, WEBP)")
      end

      if file.byte_size > MAX_IMAGE_SIZE
        errors.add(:base, "#{config[:label]}: vượt quá 5MB")
      end
    end
  end
end
