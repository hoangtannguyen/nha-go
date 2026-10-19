import { Controller } from "@hotwired/stimulus"

// Mở/đóng menu mobile khi bấm nút burger
export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("open")
  }

  close() {
    this.menuTarget.classList.remove("open")
  }
}
