import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { bestScore, recordScore } from "trivia_scores"

// Runs one round of trivia: fetches the questions, shows them one at a
// time, gives feedback after each answer, and ends with a score.
export default class extends Controller {
  static targets = [
    "loading", "game", "results", "empty",
    "counter", "score", "progress", "bar",
    "prompt", "stem", "clueBox", "clues", "clueButton",
    "choices", "orderBox", "orderList", "checkButton",
    "feedback", "nextButton",
    "resultHeading", "resultMessage", "resultBest", "reviewBox", "review"
  ]
  static values = { url: String, mode: String, difficulty: String }

  connect() {
    this.start()
  }

  disconnect() {
    this.sortable?.destroy()
  }

  async start() {
    this.show("loading")
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`Questions request failed: ${response.status}`)
      this.questions = (await response.json()).questions
    } catch (error) {
      this.loadingTarget.textContent = "The questions could not be loaded. Check your connection and reload the page."
      throw error
    }

    if (!this.questions.length) return this.show("empty")

    this.index = 0
    this.score = 0
    this.missed = []
    this.show("game")
    this.ask()
  }

  restart() {
    this.start()
  }

  // --- asking ---

  get question() {
    return this.questions[this.index]
  }

  ask() {
    const question = this.question
    this.answered = false

    this.counterTarget.textContent = `Question ${this.index + 1} of ${this.questions.length}`
    this.scoreTarget.textContent = `Score: ${this.score}`
    this.progressTarget.setAttribute("aria-valuemax", this.questions.length)
    this.progressTarget.setAttribute("aria-valuenow", this.index)
    this.barTarget.style.width = `${(this.index / this.questions.length) * 100}%`

    this.promptTarget.textContent = question.prompt
    this.stemTarget.textContent = question.stem || ""
    this.stemTarget.hidden = !question.stem
    this.feedbackTarget.hidden = true
    this.feedbackTarget.replaceChildren()
    this.nextButtonTarget.hidden = true

    this.showClues(question)
    question.kind === "order" ? this.askOrder(question) : this.askChoice(question)
    this.promptTarget.focus({ preventScroll: true })
  }

  askChoice(question) {
    this.orderBoxTarget.hidden = true
    this.choicesTarget.hidden = false
    this.choicesTarget.replaceChildren(...question.choices.map((choice) => {
      const item = document.createElement("li")
      const button = document.createElement("button")
      button.type = "button"
      button.className = "quiz-choice"
      button.textContent = choice
      button.addEventListener("click", () => this.answerChoice(choice))
      item.append(button)
      return item
    }))
  }

  // --- Who Am I? clues, shown one at a time ---

  showClues(question) {
    const clues = question.clues || []
    this.clueBoxTarget.hidden = clues.length === 0
    this.cluesTarget.replaceChildren()
    this.cluesShown = 0
    if (clues.length) this.revealClue()
  }

  revealClue() {
    const clues = this.question.clues
    const item = document.createElement("li")
    item.textContent = clues[this.cluesShown]
    this.cluesTarget.append(item)
    this.cluesShown += 1
    this.clueButtonTarget.hidden = this.answered || this.cluesShown >= clues.length
  }

  // --- answering a multiple-choice question ---

  answerChoice(choice) {
    if (this.answered) return
    const question = this.question
    const correct = choice === question.answer

    this.choicesTarget.querySelectorAll("button").forEach((button) => {
      button.disabled = true
      if (button.textContent === question.answer) this.mark(button, "correct", "Correct answer")
      else if (button.textContent === choice) this.mark(button, "wrong", "Your answer")
    })

    this.finish(correct, correct ? "Correct!" : `Not quite. The answer is ${question.answer}.`, [question.explanation])
  }

  mark(button, state, label) {
    button.classList.add(`quiz-choice-${state}`)
    const note = document.createElement("span")
    note.className = "quiz-choice-note"
    note.textContent = `${state === "correct" ? "✓" : "✗"} ${label}`
    button.append(note)
  }

  // --- putting events in order ---

  askOrder(question) {
    this.choicesTarget.hidden = true
    this.orderBoxTarget.hidden = false
    this.checkButtonTarget.hidden = false

    this.orderListTarget.replaceChildren(...question.items.map((entry) => {
      const item = document.createElement("li")
      item.className = "quiz-order-item"
      item.dataset.id = entry.id

      const label = document.createElement("span")
      label.className = "min-w-0 flex-1 font-semibold"
      label.textContent = entry.label

      item.append(label, this.moveButton(entry.label, -1), this.moveButton(entry.label, 1))
      return item
    }))

    this.sortable?.destroy()
    this.sortable = Sortable.create(this.orderListTarget, { animation: 150, filter: "button", preventOnFilter: false })
  }

  moveButton(label, direction) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "quiz-move"
    button.textContent = direction < 0 ? "↑" : "↓"
    button.setAttribute("aria-label", `Move “${label}” ${direction < 0 ? "earlier" : "later"}`)
    button.addEventListener("click", () => this.move(button.closest("li"), direction))
    return button
  }

  move(item, direction) {
    if (this.answered) return
    const sibling = direction < 0 ? item.previousElementSibling : item.nextElementSibling
    if (!sibling) return
    direction < 0 ? sibling.before(item) : sibling.after(item)
    item.querySelectorAll("button")[direction < 0 ? 0 : 1].focus()
  }

  checkOrder() {
    if (this.answered) return
    const question = this.question
    const order = [...this.orderListTarget.children].map((item) => item.dataset.id)
    const correct = order.every((id, position) => id === question.answer[position])

    this.sortable.option("disabled", true)
    this.checkButtonTarget.hidden = true
    this.orderListTarget.querySelectorAll("button").forEach((button) => { button.disabled = true })
    ;[...this.orderListTarget.children].forEach((item, position) => {
      item.classList.add(item.dataset.id === question.answer[position] ? "quiz-order-correct" : "quiz-order-wrong")
    })

    this.finish(correct, correct ? "Correct! That is the right order." : "Not quite. Here is the right order:", question.explanation)
  }

  // --- feedback, shared by both kinds of question ---

  finish(correct, headline, lines) {
    const question = this.question
    this.answered = true
    if (correct) this.score += 1
    else this.missed.push(question)

    this.scoreTarget.textContent = `Score: ${this.score}`
    this.clueButtonTarget.hidden = true

    const box = document.createElement("div")
    box.className = `quiz-feedback ${correct ? "quiz-feedback-correct" : "quiz-feedback-wrong"}`

    const heading = document.createElement("p")
    heading.className = "text-xl font-bold"
    heading.textContent = `${correct ? "✓" : "✗"} ${headline}`
    box.append(heading)

    lines.filter(Boolean).forEach((line) => {
      const paragraph = document.createElement("p")
      paragraph.className = "mt-2"
      paragraph.textContent = line
      box.append(paragraph)
    })

    if (question.link) box.append(this.linkParagraph(question.link))

    this.feedbackTarget.replaceChildren(box)
    this.feedbackTarget.hidden = false

    const last = this.index === this.questions.length - 1
    this.nextButtonTarget.textContent = last ? "See my score" : "Next question"
    this.nextButtonTarget.hidden = false
    this.nextButtonTarget.focus({ preventScroll: true })
  }

  linkParagraph(link) {
    const paragraph = document.createElement("p")
    paragraph.className = "mt-3"
    const anchor = document.createElement("a")
    anchor.href = link.url
    anchor.className = "text-link"
    anchor.textContent = link.label
    paragraph.append(anchor)
    return paragraph
  }

  next() {
    this.index += 1
    this.index < this.questions.length ? this.ask() : this.finishRound()
  }

  // --- results ---

  finishRound() {
    const total = this.questions.length
    const share = this.score / total
    const newBest = recordScore(this.modeValue, this.difficultyValue, this.score, total)
    const best = bestScore(this.modeValue, this.difficultyValue)

    this.resultHeadingTarget.textContent = `You scored ${this.score} of ${total}`
    this.resultMessageTarget.textContent =
      share === 1 ? "A perfect round." : share >= 0.75 ? "Well done. You know this history." : share >= 0.5 ? "A solid round. Review the ones you missed and try again." : "Good start. Explore the timeline and map, then try again."
    this.resultBestTarget.textContent = newBest ? "That is your best score for this game." : best ? `Your best: ${best.score} of ${best.total}` : ""

    this.reviewBoxTarget.hidden = this.missed.length === 0
    this.reviewTarget.replaceChildren(...this.missed.map((question) => {
      const item = document.createElement("li")
      item.className = "card p-4"

      const prompt = document.createElement("p")
      prompt.className = "font-semibold"
      prompt.textContent = question.stem || (question.clues ? question.clues[question.clues.length - 1] : question.prompt)

      const answer = document.createElement("p")
      answer.className = "mt-1 text-base"
      answer.textContent = question.kind === "order" ? question.explanation.join(" · ") : `Answer: ${question.answer}`

      item.append(prompt, answer)
      if (question.link) item.append(this.linkParagraph(question.link))
      return item
    }))

    this.show("results")
    this.resultHeadingTarget.focus({ preventScroll: true })
  }

  // Shows one of the four screens and hides the rest.
  show(screen) {
    for (const name of ["loading", "game", "results", "empty"]) {
      this[`${name}Target`].hidden = name !== screen
    }
  }
}
