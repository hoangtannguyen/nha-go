# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Danh mục. Slug giữ đúng giá trị cũ để link đã chia sẻ không chết.
categories = [
  { slug: "aokhoac",    name: "Áo khoác",      description: "Denim, bomber, dạ, kaki", position: 1 },
  { slug: "aothun",     name: "Áo thun",       description: "Tee, band tee, polo",     position: 2 },
  { slug: "quandai",    name: "Quần dài",      description: "Jeans, kaki, tây",        position: 3 },
  { slug: "somiveston", name: "Sơ mi / Hoodie", description: "Sơ mi, flannel, hoodie", position: 4 }
]

categories.each do |attributes|
  Category.find_or_initialize_by(slug: attributes[:slug]).update!(attributes)
end

puts "Seeded #{Category.count} categories."

categories_by_slug = Category.all.index_by(&:slug)

products = [
  { name: "Áo khoác denim retro",    category: "aokhoac",    tag: "HOT",   image: "p-jacket-denim.webp", size_label: "Size L · Nam/Nữ",  price: 285_000, position: 1 },
  { name: "Áo thun band vintage",    category: "aothun",     tag: "1 món", image: "p-tee-black.webp",    size_label: "Size M · Unisex",  price: 145_000, position: 2 },
  { name: "Quần jeans ống đứng",     category: "quandai",    tag: nil,     image: "p-jeans.webp",        size_label: "Size 30 · Nữ",     price: 220_000, position: 3 },
  { name: "Hoodie olive oversize",   category: "somiveston", tag: "HOT",   image: "p-hoodie.webp",       size_label: "Size XL · Unisex", price: 260_000, position: 4 },
  { name: "Áo sơ mi flannel đỏ",     category: "somiveston", tag: nil,     image: "p-flannel.webp",      size_label: "Size M · Unisex",  price: 190_000, position: 5 },
  { name: "Áo bomber khaki vintage", category: "aokhoac",    tag: "1 món", image: "p-bomber.webp",       size_label: "Size L · Nam/Nữ",  price: 320_000, position: 6 }
]

products.each do |attributes|
  attributes = attributes.merge(category: categories_by_slug.fetch(attributes[:category]))
  Product.find_or_initialize_by(name: attributes[:name]).update!(attributes)
end

puts "Seeded #{Product.count} products."

# Tài khoản quản trị đầu tiên.
# Mật khẩu lấy từ ENV["ADMIN_PASSWORD"], không có thì sinh ngẫu nhiên và in ra một lần.
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@nhago.local")
admin = AdminUser.find_or_initialize_by(email: admin_email)

if admin.new_record?
  password = "12345678" || SecureRandom.alphanumeric(12)
  admin.name = "Quản trị Nhà Gô"
  admin.password = password
  admin.password_confirmation = password
  admin.save!

  puts "-" * 60
  puts "Đã tạo tài khoản quản trị:"
  puts "  Email:    #{admin.email}"
  puts "  Mật khẩu: #{password}"
  puts "  Đăng nhập tại /admin/login — đổi mật khẩu ngay sau lần đầu."
  puts "-" * 60
else
  puts "Tài khoản quản trị #{admin.email} đã tồn tại, bỏ qua."
end
