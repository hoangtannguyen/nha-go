import { Controller } from "@hotwired/stimulus"

// Hiện phần tuỳ chọn phụ khi ô chính được tích; bỏ tích thì ẩn và bỏ chọn luôn các ô bên trong
export default class extends Controller {
  static targets = ["source", "panel"]

  sync() {
    const on = this.sourceTarget.checked
    this.panelTarget.hidden = !on
    if (!on) {
      this.panelTarget.querySelectorAll("input[type=checkbox]").forEach(box => { box.checked = false })
    }
  }
}
