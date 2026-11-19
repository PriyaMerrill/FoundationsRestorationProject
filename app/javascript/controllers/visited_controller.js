import { Controller } from "@hotwired/stimulus"
import { visitedPlaces, toggleVisited } from "visited_places"

// The "Mark as explored" button in a place panel.
export default class extends Controller {
  static targets = ["label", "hint", "tick"]
  static values = { slug: String }

  connect() {
    this.render()
  }

  toggle() {
    toggleVisited(this.slugValue)
    this.render()
  }

  render() {
    const visited = visitedPlaces().includes(this.slugValue)
    this.element.setAttribute("aria-pressed", visited)
    this.labelTarget.textContent = visited ? "Explored" : "Mark as explored"
    this.hintTarget.textContent = visited ? "Select to remove the stamp" : "Stamp this place on your road trip"
    this.tickTarget.style.visibility = visited ? "visible" : "hidden"
  }
}
