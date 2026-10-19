import { Controller } from "@hotwired/stimulus"

// Lọc sản phẩm theo danh mục ngay trên client, không reload trang
export default class extends Controller {
  static targets = ["chip", "card", "empty"]

  filter(event) {
    const chip = event.currentTarget
    const category = chip.dataset.cat

    this.chipTargets.forEach((item) => item.classList.toggle("active", item === chip))

    let visible = 0
    this.cardTargets.forEach((card) => {
      const match = category === "all" || card.dataset.cat === category
      card.style.display = match ? "" : "none"
      if (match) visible += 1
    })

    this.emptyTarget.style.display = visible > 0 ? "none" : "block"
  }
}
