import { Controller } from "@hotwired/stimulus"

// Đánh dấu link menu đang active theo path + hash (#hang-moi, #lien-he...)
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("hashchange", this.update)
    this.update()
  }

  disconnect() {
    window.removeEventListener("hashchange", this.update)
  }

  select(event) {
    this.mark(event.currentTarget)
  }

  update() {
    const current = this.linkTargets.find(link =>
      link.pathname === window.location.pathname && link.hash === window.location.hash
    )
    this.mark(current)
  }

  mark(active) {
    this.linkTargets.forEach(link => {
      link.classList.toggle("is-active", link === active)
      if (link === active) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }
}
