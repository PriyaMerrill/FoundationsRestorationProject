import { Controller } from "@hotwired/stimulus"
import { bestScore } from "trivia_scores"

// The trivia page's scoreboard: each game's best score for the chosen
// level, and a tally of how many games have been played at that level.
export default class extends Controller {
  static targets = ["difficulty", "best", "summary"]

  connect() {
    this.render()
  }

  render() {
    const difficulty = this.difficultyTargets.find((input) => input.checked)?.value
    let played = 0

    this.bestTargets.forEach((element) => {
      const best = bestScore(element.dataset.mode, difficulty)
      if (best) played += 1
      element.textContent = best ? `★ Your best: ${best.score} of ${best.total}` : "Not played yet"
      element.classList.toggle("game-best-set", Boolean(best))
    })

    if (this.hasSummaryTarget) {
      const total = this.bestTargets.length
      this.summaryTarget.textContent =
        played === 0 ? "Play a game to get on the board" : played === total ? `All ${total} games played at this level` : `${played} of ${total} games played at this level`
    }
  }
}
