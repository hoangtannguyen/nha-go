import { Controller } from "@hotwired/stimulus"

// Copy link sản phẩm vào clipboard, đổi nhãn nút tạm thời để báo đã copy
export default class extends Controller {
  static values = { text: String, done: { type: String, default: "✓ Đã copy" } }

  async copy(event) {
    event.preventDefault()
    try {
      await this.write(this.textValue)
      this.flash(this.doneValue)
    } catch {
      this.flash("Không copy được")
    }
  }

  async write(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text)
    }
    // Fallback khi chạy http (không phải https/localhost)
    const area = document.createElement("textarea")
    area.value = text
    area.setAttribute("readonly", "")
    area.style.position = "fixed"
    area.style.opacity = "0"
    document.body.appendChild(area)
    area.select()
    const ok = document.execCommand("copy")
    area.remove()
    if (!ok) throw new Error("copy failed")
  }

  flash(message) {
    if (this.original === undefined) this.original = this.element.textContent
    clearTimeout(this.timer)
    this.element.textContent = message
    this.timer = setTimeout(() => { this.element.textContent = this.original }, 1800)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
