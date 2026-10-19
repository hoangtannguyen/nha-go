import { Controller } from "@hotwired/stimulus"

// Xem trước ảnh vừa chọn, cho bỏ bớt file trước khi upload.
//
// Mặc định input[type=file] THAY TOÀN BỘ danh sách mỗi lần chọn, nên chọn 1 ảnh
// rồi chọn tiếp ảnh khác sẽ mất ảnh trước. Controller giữ danh sách tích luỹ
// riêng rồi ghi ngược lại vào input để form submit được đầy đủ.
export default class extends Controller {
  static targets = ["input", "list", "warning"]
  static values = {
    max: { type: Number, default: 8 },
    existing: { type: Number, default: 0 },
    maxSize: { type: Number, default: 5 * 1024 * 1024 }
  }

  initialize() {
    this.files = []
  }

  connect() {
    this.files = Array.from(this.inputTarget.files || [])
    this.render()
  }

  // Gọi mỗi lần người dùng chọn file: cộng dồn thay vì thay thế
  preview() {
    const picked = Array.from(this.inputTarget.files || [])

    picked.forEach((file) => {
      if (!this.files.some((existing) => this.sameFile(existing, file))) {
        this.files.push(file)
      }
    })

    this.syncInput()
    this.render()
  }

  removeAt(index) {
    this.files.splice(index, 1)
    this.syncInput()
    this.render()
  }

  clearAll() {
    this.files = []
    this.syncInput()
    this.render()
  }

  sameFile(a, b) {
    return a.name === b.name && a.size === b.size && a.lastModified === b.lastModified
  }

  // Ghi danh sách tích luỹ ngược vào input (gán .files không kích hoạt lại change)
  syncInput() {
    const transfer = new DataTransfer()
    this.files.forEach((file) => transfer.items.add(file))
    this.inputTarget.files = transfer.files
  }

  render() {
    this.listTarget.replaceChildren()
    this.listTarget.hidden = this.files.length === 0

    this.files.forEach((file, index) => this.listTarget.append(this.buildItem(file, index)))

    if (this.files.length > 0) this.listTarget.append(this.buildClearButton())

    this.renderWarning()
  }

  buildItem(file, index) {
    const item = document.createElement("figure")
    item.className = "photo-item photo-item-new"
    if (file.size > this.maxSizeValue) item.classList.add("photo-item-bad")

    const image = document.createElement("img")
    image.src = URL.createObjectURL(file)
    image.alt = file.name
    image.addEventListener("load", () => URL.revokeObjectURL(image.src), { once: true })
    item.append(image)

    const badge = document.createElement("span")
    badge.className = "photo-badge photo-badge-new"
    badge.textContent = this.existingValue === 0 && index === 0 ? "Ảnh đại diện" : `Mới ${index + 1}`
    item.append(badge)

    const caption = document.createElement("figcaption")
    caption.className = "photo-caption"
    caption.textContent = `${file.name} · ${this.humanSize(file.size)}`
    item.append(caption)

    const remove = document.createElement("button")
    remove.type = "button"
    remove.className = "photo-remove"
    remove.textContent = "Bỏ"
    remove.addEventListener("click", () => this.removeAt(index))
    item.append(remove)

    return item
  }

  buildClearButton() {
    const wrapper = document.createElement("div")
    wrapper.className = "photo-clear"

    const button = document.createElement("button")
    button.type = "button"
    button.className = "btn-sm"
    button.textContent = `Bỏ hết ${this.files.length} ảnh vừa chọn`
    button.addEventListener("click", () => this.clearAll())

    wrapper.append(button)
    return wrapper
  }

  renderWarning() {
    if (!this.hasWarningTarget) return

    const total = this.existingValue + this.files.length
    const oversized = this.files.filter((file) => file.size > this.maxSizeValue)

    const messages = []
    if (total > this.maxValue) messages.push(`Tổng ${total} ảnh, vượt quá ${this.maxValue} ảnh cho phép.`)
    if (oversized.length > 0) messages.push(`${oversized.map((file) => file.name).join(", ")} vượt quá 5MB.`)

    this.warningTarget.textContent = messages.join(" ")
    this.warningTarget.hidden = messages.length === 0
  }

  humanSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
    return `${(bytes / 1024 / 1024).toFixed(1)} MB`
  }
}
