import { Controller } from "@hotwired/stimulus"

// Chèn dấu phân cách hàng nghìn khi gõ giá tiền: 285000 -> 285.000
export default class extends Controller {
  static values = { separator: { type: String, default: "." } }

  connect() {
    this.format()
  }

  format() {
    const input = this.element
    const caret = input.selectionStart ?? input.value.length
    const digitsBeforeCaret = input.value.slice(0, caret).replace(/\D/g, "").length

    const digits = input.value.replace(/\D/g, "")
    const formatted = digits ? digits.replace(/\B(?=(\d{3})+(?!\d))/g, this.separatorValue) : ""

    if (formatted === input.value) return

    input.value = formatted
    this.restoreCaret(input, formatted, digitsBeforeCaret)
  }

  // Đặt con trỏ lại sau đúng số chữ số như trước khi format
  restoreCaret(input, formatted, digitsBeforeCaret) {
    if (input.selectionStart === null) return

    let seen = 0
    let position = 0

    while (position < formatted.length && seen < digitsBeforeCaret) {
      if (/\d/.test(formatted[position])) seen += 1
      position += 1
    }

    input.setSelectionRange(position, position)
  }
}
