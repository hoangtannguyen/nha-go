import { Controller } from "@hotwired/stimulus"

// Chọn tỉnh/thành xong thì nạp danh sách phường/xã tương ứng
export default class extends Controller {
  static targets = ["province", "ward"]
  static values = {
    url: String,
    selected: String,
    placeholder: { type: String, default: "— chọn phường/xã —" }
  }

  connect() {
    // Giữ lại lựa chọn cũ khi form render lại vì lỗi validate
    if (this.provinceTarget.value) this.load({ keepSelected: true })
  }

  change() {
    this.load({ keepSelected: false })
  }

  async load({ keepSelected }) {
    const code = this.provinceTarget.value

    if (!code) {
      this.fill([], "")
      return
    }

    this.setLoading(true)

    try {
      const response = await fetch(`${this.urlValue}?province_code=${encodeURIComponent(code)}`, {
        headers: { Accept: "application/json" }
      })
      const data = await response.json()

      this.fill(data.wards || [], keepSelected ? this.selectedValue : "")
    } catch (error) {
      this.wardTarget.innerHTML = ""
      this.wardTarget.append(new Option("Không tải được danh sách, thử lại sau", ""))
    } finally {
      this.setLoading(false)
    }
  }

  fill(wards, selected) {
    this.wardTarget.innerHTML = ""
    this.wardTarget.append(new Option(this.placeholderValue, ""))

    wards.forEach((ward) => {
      const option = new Option(ward.name, ward.code)
      option.selected = String(ward.code) === String(selected)
      this.wardTarget.append(option)
    })

    this.wardTarget.disabled = wards.length === 0
  }

  setLoading(loading) {
    this.wardTarget.disabled = loading
    if (loading) {
      this.wardTarget.innerHTML = ""
      this.wardTarget.append(new Option("Đang tải...", ""))
    }
  }
}
