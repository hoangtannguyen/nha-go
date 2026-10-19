# Danh sách đơn vị hành chính 2 cấp (tỉnh/thành → phường/xã), hiệu lực 01/07/2025.
#
# Dữ liệu nhúng sẵn trong db/data thay vì gọi API lúc khách thanh toán — checkout
# không nên phụ thuộc vào bên thứ ba. Cập nhật lại bằng:
#   bin/rails vietnam_address:refresh
class VietnamAddress
  DATA_PATH = Rails.root.join("db/data/vietnam_administrative_units.json")

  class << self
    def data
      @data ||= JSON.parse(DATA_PATH.read, symbolize_names: true)
    end

    def reload!
      @data = nil
      @provinces_by_code = nil
      data
    end

    def source
      data[:source]
    end

    def fetched_on
      data[:fetched_on]
    end

    def provinces
      data[:provinces]
    end

    # [[tên hiển thị, code], ...] cho select
    def province_options
      provinces.map { |province| [ province[:name], province[:code] ] }
    end

    def province(code)
      provinces_by_code[code.to_i]
    end

    def province_name(code)
      province(code)&.dig(:name)
    end

    def wards(province_code)
      province(province_code)&.dig(:wards) || []
    end

    def ward_options(province_code)
      wards(province_code).map { |ward| [ ward[:name], ward[:code] ] }
    end

    def ward(province_code, ward_code)
      wards(province_code).find { |item| item[:code] == ward_code.to_i }
    end

    def ward_name(province_code, ward_code)
      ward(province_code, ward_code)&.dig(:name)
    end

    def province_code?(code)
      code.present? && province(code).present?
    end

    def ward_code?(province_code, ward_code)
      ward_code.present? && ward(province_code, ward_code).present?
    end

    private

    def provinces_by_code
      @provinces_by_code ||= provinces.index_by { |province| province[:code] }
    end
  end
end
