import { Controller } from "@hotwired/stimulus"

// Đổi select là gửi form luôn, khỏi cần nút "Áp dụng"
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
