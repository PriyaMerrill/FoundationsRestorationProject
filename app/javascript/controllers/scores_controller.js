import { Controller } from "@hotwired/stimulus"
import { bestScore } from "trivia_scores"

// Shows each game's best score for the chosen difficulty on the trivia page.
export default class extends Controller {
  static targets = ["difficulty", "best"]

  connect() {
    this.render()
  }

  render() {
    const difficulty = this.difficultyTargets.find((input) => input.checked)?.value
    this.bestTargets.forEach((element) => {
      const best = bestScore(element.dataset.mode, difficulty)
      element.textContent = best ? `Your best: ${best.score} of ${best.total}` : "Not played yet"
    })
  }
}
