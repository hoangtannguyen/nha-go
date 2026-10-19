class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  def subtotal
    price * quantity
  end
end
