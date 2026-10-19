require "net/http"
require "json"

namespace :vietnam_address do
  SOURCE_URL = "https://provinces.open-api.vn/api/v2/?depth=2".freeze

  # API gắn sai: Quảng Ninh / Bắc Ninh / Đồng Nai là TỈNH, không phải thành phố TW.
  # Chỉ có 6 thành phố trực thuộc trung ương.
  CENTRAL_CITY_CODES = [ 1, 31, 46, 48, 79, 92 ].freeze

  desc "Tải lại danh sách tỉnh/thành và phường/xã vào db/data"
  task refresh: :environment do
    puts "Đang tải #{SOURCE_URL} ..."
    raw = JSON.parse(Net::HTTP.get(URI(SOURCE_URL)))

    provinces = raw.sort_by { |province| province["code"] }.map do |province|
      central_city = CENTRAL_CITY_CODES.include?(province["code"])
      bare = province["name"].sub(/\A(Thành phố|Tỉnh)\s+/, "").strip

      {
        code: province["code"],
        name: "#{central_city ? 'Thành phố' : 'Tỉnh'} #{bare}",
        short_name: bare,
        type: central_city ? "thanh_pho_trung_uong" : "tinh",
        wards: province["wards"].sort_by { |ward| ward["name"] }.map do |ward|
          { code: ward["code"], name: ward["name"], type: ward["division_type"] }
        end
      }
    end

    payload = {
      source: SOURCE_URL,
      fetched_on: Date.current.to_s,
      note: "Đơn vị hành chính 2 cấp, hiệu lực 01/07/2025. " \
            "Đã sửa tên 3 tỉnh bị API gắn nhầm thành \"Thành phố\": Quảng Ninh (22), Bắc Ninh (24), Đồng Nai (75).",
      province_count: provinces.size,
      ward_count: provinces.sum { |province| province[:wards].size },
      provinces: provinces
    }

    VietnamAddress::DATA_PATH.write(JSON.generate(payload))
    VietnamAddress.reload!

    puts "Xong: #{payload[:province_count]} tỉnh/thành, #{payload[:ward_count]} phường/xã."
    puts "Ghi vào #{VietnamAddress::DATA_PATH.relative_path_from(Rails.root)}"
  end
end
