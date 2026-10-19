# Tích hợp Giao Hàng Tiết Kiệm (GHTK) — https://api.ghtk.vn/docs
module Ghtk
  CARRIER = "ghtk".freeze
  CARRIER_NAME = "Giao Hàng Tiết Kiệm (GHTK)".freeze
  # Trang tra cứu công khai của GHTK; tài liệu API không công bố link tra cứu theo từng mã
  LOOKUP_URL = "https://i.ghtk.vn/".freeze

  class Error < StandardError; end
  class NotConfiguredError < Error; end
end
