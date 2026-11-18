// Remembers which places a visitor has explored. It is saved in the
// browser (local storage), so it needs no account and stays on this device.
const KEY = "restoration:visited-places"

export function visitedPlaces() {
  try {
    const saved = JSON.parse(localStorage.getItem(KEY))
    return Array.isArray(saved) ? saved : []
  } catch {
    return []
  }
}

export function toggleVisited(slug) {
  const visited = new Set(visitedPlaces())
  visited.has(slug) ? visited.delete(slug) : visited.add(slug)

  try {
    localStorage.setItem(KEY, JSON.stringify([...visited]))
  } catch {
    // Storage can be unavailable (private browsing); the button still works for this page view.
  }
  window.dispatchEvent(new CustomEvent("visited:change"))
}
