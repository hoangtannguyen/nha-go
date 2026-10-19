import { Controller } from "@hotwired/stimulus"

// Hiện dần các khối khi cuộn tới (thêm class "in" cho .reveal)
export default class extends Controller {
  static targets = ["item"]

  initialize() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return

        entry.target.classList.add("in")
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.15 })
  }

  itemTargetConnected(item) {
    this.observer.observe(item)
  }

  disconnect() {
    this.observer.disconnect()
  }
}
