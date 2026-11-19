import { Controller } from "@hotwired/stimulus"

// One period's row of events on the timeline. Choosing a dot on the line
// brings that event to the front: the left edge of the row on a wide
// screen, the top of the screen on a narrow one.
export default class extends Controller {
  bringToFront(event) {
    const item = event.currentTarget.closest("li")
    const smooth = !window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const sideways = this.element.scrollWidth > this.element.clientWidth

    if (sideways) {
      // Where the event sits now, measured from the row's left edge.
      const offset = item.getBoundingClientRect().left - this.element.getBoundingClientRect().left
      this.element.scrollTo({ left: this.element.scrollLeft + offset, behavior: smooth ? "smooth" : "auto" })
    } else {
      item.scrollIntoView({ block: "start", behavior: smooth ? "smooth" : "auto" })
    }

    this.element.querySelectorAll(".timeline-dot[aria-current]").forEach((dot) => dot.removeAttribute("aria-current"))
    event.currentTarget.setAttribute("aria-current", "true")
  }
}
