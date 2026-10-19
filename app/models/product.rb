class Product < ApplicationRecord
  MAX_PHOTOS = 8
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTO_SIZE = 5.megabytes

  belongs_to :category
  has_many :order_items, dependent: :restrict_with_error
  has_many_attached :photos

  delegate :name, :slug, to: :category, prefix: true, allow_nil: true

  # Bảng màu và size dùng chung cho form admin. Sửa ở đây là cả app đổi theo.
  COLOR_OPTIONS = {
    "den"        => { label: "Đen",        hex: "#2e2a24" },
    "trang"      => { label: "Trắng",      hex: "#f5f1e8" },
    "xam"        => { label: "Xám",        hex: "#9a958c" },
    "be"         => { label: "Be",         hex: "#ddd0b4" },
    "nau"        => { label: "Nâu",        hex: "#6b4a2f" },
    "xanh_navy"  => { label: "Xanh navy",  hex: "#2c4257" },
    "xanh_reu"   => { label: "Xanh rêu",   hex: "#5a6b3b" },
    "xanh_nhat"  => { label: "Xanh nhạt",  hex: "#9ec1d4" },
    "do"         => { label: "Đỏ",         hex: "#c1502e" },
    "hong"       => { label: "Hồng",       hex: "#e0a0a8" },
    "vang"       => { label: "Vàng",       hex: "#e8b04b" },
    "nhieu_mau"  => { label: "Nhiều màu",  hex: nil }
  }.freeze

  SIZE_OPTIONS = {
    "Áo"   => %w[XS S M L XL XXL Freesize],
    "Quần" => %w[27 28 29 30 31 32 33 34]
  }.freeze

  ALL_SIZES = SIZE_OPTIONS.values.flatten.freeze

  validates :name, presence: { message: "không được để trống" }
  validates :price, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :photos_must_be_images
  validate :colors_must_be_known
  validate :sizes_must_be_known

  before_validation :clean_option_lists
  # Có hàng lại thì tự hiện lại, không để món còn bán mà bị ẩn
  before_validation { self.hidden = false unless sold_out? }

  scope :ordered, -> { order(:position, :id) }
  scope :in_category, ->(category) { where(category: category) }
  # Đặt TRƯỚC các order khác để món đã bán hết luôn xuống cuối
  scope :available_first, -> { order(:sold_out) }
  scope :visible, -> { where(hidden: false) }

  def hot?
    tag == "HOT"
  end

  # Ảnh đầu tiên dùng làm ảnh đại diện ngoài danh sách
  def main_photo
    photos.attached? ? photos.first : nil
  end

  def extra_photos
    photos.attached? ? photos.drop(1) : []
  end

  def photos_count
    photos.attached? ? photos.size : 0
  end

  def colors
    super || []
  end

  def sizes
    super || []
  end

  def color_names
    colors.filter_map { |value| COLOR_OPTIONS.dig(value, :label) }
  end

  def color_swatches
    colors.filter_map { |value| COLOR_OPTIONS[value]&.merge(value: value) }
  end

  # Ưu tiên danh sách size đã chọn, chưa có thì dùng mô tả size tự do
  def size_summary
    sizes.any? ? "Size #{sizes.join(', ')}" : size_label
  end

  private

  def clean_option_lists
    self.colors = Array(colors).map(&:to_s).reject(&:blank?).uniq
    self.sizes = Array(sizes).map(&:to_s).reject(&:blank?).uniq
  end

  def colors_must_be_known
    unknown = colors - COLOR_OPTIONS.keys
    errors.add(:colors, "có giá trị không hợp lệ: #{unknown.join(', ')}") if unknown.any?
  end

  def sizes_must_be_known
    unknown = sizes - ALL_SIZES
    errors.add(:sizes, "có giá trị không hợp lệ: #{unknown.join(', ')}") if unknown.any?
  end

  def photos_must_be_images
    return unless photos.attached?

    if photos.size > MAX_PHOTOS
      errors.add(:photos, "tối đa #{MAX_PHOTOS} ảnh mỗi sản phẩm (đang có #{photos.size})")
    end

    photos.each do |photo|
      unless photo.content_type.in?(PHOTO_TYPES)
        errors.add(:photos, "#{photo.filename} phải là file ảnh (JPG, PNG, WEBP)")
      end

      if photo.byte_size > MAX_PHOTO_SIZE
        errors.add(:photos, "#{photo.filename} vượt quá 5MB")
      end
    end
  end
end
