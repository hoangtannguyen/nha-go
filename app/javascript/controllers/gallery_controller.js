import { Controller } from "@hotwired/stimulus"

// Đổi ảnh lớn khi bấm vào ảnh nhỏ bên dưới
export default class extends Controller {
  static targets = ["main", "thumb"]

  select(event) {
    const thumb = event.currentTarget
    const source = thumb.dataset.full

    if (!source) return

    this.mainTarget.src = source
    this.mainTarget.alt = thumb.querySelector("img")?.alt || this.mainTarget.alt

    this.thumbTargets.forEach((item) => item.classList.toggle("is-active", item === thumb))
  }
}
