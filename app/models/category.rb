class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.to_s.strip }
  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase }

  validates :name, presence: { message: "không được để trống" },
                   uniqueness: { case_sensitive: false, message: "đã tồn tại" }
  validates :slug, presence: { message: "không được để trống" },
                   uniqueness: { message: "đã tồn tại" },
                   format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/,
                             message: "chỉ gồm chữ thường, số và dấu gạch ngang",
                             allow_blank: true }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :assign_slug
  before_validation :assign_position, on: :create

  scope :ordered, -> { order(:position, :id) }

  def products_count
    products.size
  end

  # Bỏ dấu tiếng Việt rồi tạo slug. ActiveSupport#parameterize không xử lý được
  # các ký tự tiếng Việt ở dải Latin Extended Additional (ạ, ế, ữ...).
  def self.slugify(text)
    marks = {
      "a" => "àáạảãâầấậẩẫăằắặẳẵ", "e" => "èéẹẻẽêềếệểễ", "i" => "ìíịỉĩ",
      "o" => "òóọỏõôồốộổỗơờớợởỡ", "u" => "ùúụủũưừứựửữ", "y" => "ỳýỵỷỹ", "d" => "đ"
    }

    normalized = text.to_s.unicode_normalize(:nfc).downcase
    marks.each { |plain, accented| normalized = normalized.tr(accented, plain * accented.length) }

    normalized.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  end

  private

  def assign_slug
    return if slug.present?

    self.slug = self.class.slugify(name)
  end

  def assign_position
    return if position.present? && position.positive?

    self.position = (Category.maximum(:position) || 0) + 1
  end
end
