# Giỏ hàng lưu trong session, không đụng DB.
# Cấu trúc: session[:cart] = { "<product_id>" => quantity }
class Cart
  SESSION_KEY = :cart

  def initialize(session)
    @session = session
    @items = session[SESSION_KEY] || {}
  end

  def add(product, quantity = 1)
    key = key_for(product)
    @items[key] = @items.fetch(key, 0) + quantity.to_i
    persist
  end

  def update(product, quantity)
    quantity = quantity.to_i

    if quantity > 0
      @items[key_for(product)] = quantity
    else
      @items.delete(key_for(product))
    end

    persist
  end

  def remove(product)
    @items.delete(key_for(product))
    persist
  end

  def clear
    @items = {}
    persist
  end

  def include?(product)
    @items.key?(key_for(product))
  end

  def quantity_for(product)
    @items.fetch(key_for(product), 0)
  end

  # [[product, quantity], ...] — bỏ qua sản phẩm đã bị xoá khỏi DB
  def entries
    @entries ||= begin
      products = Product.where(id: @items.keys).index_by { |product| product.id.to_s }
      @items.filter_map do |id, quantity|
        product = products[id]
        [ product, quantity ] if product
      end
    end
  end

  def count
    entries.sum { |_product, quantity| quantity }
  end

  def total
    entries.sum { |product, quantity| product.selling_price * quantity }
  end

  def empty?
    entries.empty?
  end

  private

  def key_for(product)
    product.id.to_s
  end

  # Gán lại để đánh dấu session đã thay đổi (sửa hash tại chỗ sẽ không được lưu)
  def persist
    @entries = nil
    @session[SESSION_KEY] = @items
    self
  end
end
