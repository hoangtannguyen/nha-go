ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # KHÔNG chạy song song. `with: :threads` mở số thread bằng số CPU nhưng
    # database.yml chỉ cấp max_connections: 5 -> ConnectionTimeoutError. Ngoài ra
    # transactional fixtures giữ transaction GHI suốt mỗi test, nhiều thread ghi
    # cùng lúc vào một file SQLite sẽ ném "database is locked". Windows không fork
    # được nên cũng không chuyển sang `:processes` (vốn tách file DB riêng) được.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
