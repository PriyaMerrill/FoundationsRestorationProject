import { Controller } from "@hotwired/stimulus"

// The slide-over panel. It opens whenever its Turbo Frame loads a record,
// and remembers what is open in the page address (?event=liberty-jail) so
// the view can be shared or bookmarked.
export default class extends Controller {
  static targets = ["drawer", "backdrop", "frame", "closeButton"]
  static values = { param: String }

  open() {
    if (!this.isOpen) this.opener = document.activeElement
    this.isOpen = true

    // "inert" keeps the off-screen drawer out of reach of the keyboard and
    // screen readers; removing it makes the drawer usable.
    this.drawerTarget.inert = false
    this.drawerTarget.classList.remove("translate-x-full")
    this.drawerTarget.classList.add("shadow-2xl")
    this.backdropTarget.classList.remove("hidden")
    this.closeButtonTarget.focus({ preventScroll: true })

    this.remember(this.frameTarget.querySelector("[data-panel-key]")?.dataset.panelKey)
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false

    this.drawerTarget.inert = true
    this.drawerTarget.classList.add("translate-x-full")
    this.drawerTarget.classList.remove("shadow-2xl")
    this.backdropTarget.classList.add("hidden")

    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
    this.remember(null)

    if (this.opener?.isConnected) this.opener.focus({ preventScroll: true })
    this.opener = null
  }

  // Keeps the address bar in step with the panel without reloading the page.
  remember(key) {
    if (!this.paramValue) return

    const url = new URL(window.location.href)
    key ? url.searchParams.set(this.paramValue, key) : url.searchParams.delete(this.paramValue)
    history.replaceState(history.state, "", url)
  }
}
