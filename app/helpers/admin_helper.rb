module AdminHelper
  STATUS_CLASSES = {
    "pending"   => "st-pending",
    "confirmed" => "st-confirmed",
    "shipped"   => "st-shipped",
    "cancelled" => "st-cancelled"
  }.freeze

  def admin_nav_class(section)
    current = controller_name == section
    [ "admin-nav-link", ("is-active" if current) ].compact.join(" ")
  end

  def order_status_badge(order)
    tag.span order_status_label(order),
             class: "status-badge #{STATUS_CLASSES.fetch(order.status, '')}"
  end
end
