import { Controller } from "@hotwired/stimulus"
import { visitedPlaces, toggleVisited } from "visited_places"

// The "Mark as explored" button in a place panel.
export default class extends Controller {
  static targets = ["label"]
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
    this.labelTarget.textContent = visited ? "Explored ✓" : "Mark as explored"
  }
}
