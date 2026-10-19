# Đọc cấu hình GHTK từ Rails credentials (khoá `ghtk:`) hoặc biến môi trường `GHTK_*`.
# Credentials được ưu tiên. Không có giá trị mặc định cho token/địa chỉ lấy hàng:
# thiếu thì báo lỗi chứ không gửi dữ liệu giả lên GHTK.
module Ghtk
  class Config
    STAGING_URL = "https://services-staging.ghtklab.com".freeze

    REQUIRED = %i[api_token pick_name pick_tel].freeze
    PICK_ADDRESS = %i[pick_address pick_province pick_ward].freeze

    def api_token      = setting(:api_token)
    def client_source  = setting(:client_source)
    def webhook_hash   = setting(:webhook_hash)
    def pick_address_id = setting(:pick_address_id)
    def transport      = setting(:transport)

    # Mặc định trỏ staging để không vô tình tạo vận đơn thật; production phải đặt rõ
    def base_url
      setting(:base_url) || STAGING_URL
    end

    def default_item_weight_kg
      value = setting(:default_item_weight_kg)
      Float(value) if value
    rescue ArgumentError
      nil
    end

    def freeship?
      setting(:is_freeship) == "1"
    end

    def pick
      %i[pick_name pick_tel pick_address pick_province pick_district pick_ward]
        .index_with { |key| setting(key) }.compact
    end

    def missing_keys
      keys = REQUIRED.reject { |key| setting(key) }
      keys += PICK_ADDRESS.reject { |key| setting(key) } if pick_address_id.blank?
      keys << :default_item_weight_kg unless default_item_weight_kg&.positive?
      keys
    end

    def assert_configured!
      missing = missing_keys
      return if missing.empty?

      raise NotConfiguredError,
            "Chưa cấu hình GHTK: thiếu #{missing.map { |key| "GHTK_#{key.upcase}" }.join(', ')}"
    end

    private

    def setting(key)
      Rails.application.credentials.dig(:ghtk, key).to_s.presence ||
        ENV["GHTK_#{key.upcase}"].to_s.strip.presence
    end
  end
end
