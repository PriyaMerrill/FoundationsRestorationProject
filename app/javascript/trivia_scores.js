// Best trivia scores, saved in the browser (local storage) so they need
// no account and stay on this device.
const KEY = "restoration:trivia-best"

function all() {
  try {
    const saved = JSON.parse(localStorage.getItem(KEY))
    return saved && typeof saved === "object" ? saved : {}
  } catch {
    return {}
  }
}

export function bestScore(mode, difficulty) {
  return all()[`${mode}:${difficulty}`] || null
}

// Saves the score if it beats the best so far. Returns true for a new best.
export function recordScore(mode, difficulty, score, total) {
  const scores = all()
  const key = `${mode}:${difficulty}`
  const best = scores[key]
  if (best && best.score / best.total >= score / total) return false

  scores[key] = { score, total }
  try {
    localStorage.setItem(KEY, JSON.stringify(scores))
  } catch {
    // Storage can be unavailable (private browsing); the game still works.
  }
  return true
}
