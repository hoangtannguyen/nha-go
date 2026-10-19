require "net/http"

# Gọi Open API của GHTK. Chỉ lo HTTP và parse JSON; ý nghĩa nghiệp vụ của
# response (success/false, trùng mã đơn...) do nơi gọi xử lý.
module Ghtk
  class Client
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 20

    NETWORK_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, OpenSSL::SSL::SSLError,
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
    ].freeze

    attr_reader :config

    def initialize(config = Config.new)
      @config = config
    end

    # POST /services/shipment/order
    def create_order(payload)
      config.assert_configured!
      request(Net::HTTP::Post, "/services/shipment/order", payload)
    end

    # GET /services/shipment/v2/{mã GHTK hoặc mã đơn đối tác}
    def order_status(tracking_code)
      raise NotConfiguredError, "Chưa cấu hình GHTK: thiếu GHTK_API_TOKEN" if config.api_token.blank?

      request(Net::HTTP::Get, "/services/shipment/v2/#{ERB::Util.url_encode(tracking_code)}")
    end

    private

    def request(klass, path, body = nil)
      uri = URI.join(config.base_url, path)
      req = klass.new(uri)
      req["Token"] = config.api_token
      req["X-Client-Source"] = config.client_source if config.client_source.present?
      req["Accept"] = "application/json"
      if body
        req["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(req)
      end

      parse(response)
    rescue *NETWORK_ERRORS => e
      raise Error, "Không kết nối được GHTK (#{e.class.name})"
    end

    def parse(response)
      if response.code == "401" || response.code == "403"
        raise Error, "GHTK từ chối xác thực (HTTP #{response.code}) — kiểm tra token và quyền của token"
      end

      data = JSON.parse(response.body.to_s)
      raise Error, "GHTK trả về dữ liệu không hợp lệ" unless data.is_a?(Hash)

      data
    rescue JSON::ParserError
      raise Error, "GHTK trả HTTP #{response.code} không phải JSON"
    end
  end
end
