class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Nhà Gô <no-reply@nhago.local>")
  layout "mailer"

  # Mailer không tự nạp helper như controller, phải khai báo mới dùng được price_vnd/zalo_url
  helper :application
end
