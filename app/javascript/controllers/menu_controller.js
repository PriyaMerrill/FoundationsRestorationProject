import { Controller } from "@hotwired/stimulus"

// Opens and closes the mobile navigation menu.
export default class extends Controller {
  static targets = ["button", "panel", "openIcon", "closeIcon"]

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.setOpen(true)
  }

  close() {
    if (this.isOpen) this.setOpen(false)
  }

  get isOpen() {
    return this.buttonTarget.getAttribute("aria-expanded") === "true"
  }

  setOpen(open) {
    this.buttonTarget.setAttribute("aria-expanded", open)
    this.panelTarget.classList.toggle("hidden", !open)
    this.openIconTarget.classList.toggle("hidden", open)
    this.closeIconTarget.classList.toggle("hidden", !open)
  }
}
