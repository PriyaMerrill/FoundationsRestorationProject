import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import { visitedPlaces } from "visited_places"

// The Road Trip map. Draws a marker for each place, opens a place in the
// slide-over panel when its marker is chosen, filters by kind of place,
// shows the road-trip route, and marks the places a visitor has explored.
export default class extends Controller {
  static targets = ["canvas", "filter", "item", "routeButton", "routeNote", "progress", "empty"]
  static values = { places: Array, selected: String }

  connect() {
    this.kind = ""
    this.markers = new Map()

    this.map = L.map(this.canvasTarget, { scrollWheelZoom: false })
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    this.placesValue.forEach((place) => {
      const marker = L.marker([place.lat, place.lng], { title: place.name, alt: place.name, keyboard: true })
      marker.on("click", () => this.openPlace(place))
      marker.addTo(this.map)
      this.markers.set(place.slug, marker)
    })

    const stops = this.placesValue.filter((place) => place.stop).sort((a, b) => a.stop - b.stop)
    this.route = L.polyline(stops.map((place) => [place.lat, place.lng]), {
      color: "#96782c", weight: 3, dashArray: "8 8", interactive: false
    })

    this.refresh()
    this.fitToVisible()
    if (this.selectedValue) this.focusOn(this.selectedValue)
  }

  disconnect() {
    this.map?.remove()
  }

  // --- choosing a place ---

  // Loads the place into the slide-over panel, which opens when it arrives.
  openPlace(place) {
    const frame = document.getElementById("panel")
    if (frame) frame.src = place.url
  }

  // Runs whenever the panel shows a record, however it was opened.
  recordOpened(event) {
    if (event.target.id !== "panel") return
    const slug = event.target.querySelector("[data-panel-key]")?.dataset.panelKey
    if (this.markers.has(slug)) this.focusOn(slug)
  }

  recordClosed() {
    this.selectedValue = ""
    this.refresh()
  }

  focusOn(slug) {
    this.selectedValue = slug
    const place = this.placesValue.find((candidate) => candidate.slug === slug)
    if (place) this.map.setView([place.lat, place.lng], Math.max(this.map.getZoom(), 7))
    this.refresh()
  }

  // --- filters ---

  filter(event) {
    this.kind = event.currentTarget.dataset.kind
    this.filterTargets.forEach((button) => button.setAttribute("aria-pressed", button.dataset.kind === this.kind))
    this.refresh()
    this.fitToVisible()
  }

  matches(kinds) {
    return !this.kind || kinds.includes(this.kind)
  }

  // --- road-trip route ---

  toggleRoute() {
    const show = !this.map.hasLayer(this.route)
    show ? this.route.addTo(this.map) : this.route.remove()
    this.routeButtonTarget.setAttribute("aria-pressed", show)
    this.routeNoteTarget.hidden = !show
    if (show) this.map.fitBounds(this.route.getBounds(), { padding: [30, 30] })
  }

  // --- explored places ---

  refreshVisited() {
    this.refresh()
  }

  // --- drawing ---

  // Brings markers, the list and the progress count in line with the
  // current filter, selection and explored places.
  refresh() {
    const visited = visitedPlaces()

    this.placesValue.forEach((place) => {
      const marker = this.markers.get(place.slug)
      const shown = this.matches(place.kinds)
      const state = { visited: visited.includes(place.slug), active: place.slug === this.selectedValue }

      marker.setIcon(this.icon(place, state))
      marker.setZIndexOffset(state.active ? 1000 : 0)
      shown ? marker.addTo(this.map) : marker.remove()
    })

    let shownCount = 0
    this.itemTargets.forEach((item) => {
      const shown = this.matches(item.dataset.kinds.split(" "))
      const isVisited = visited.includes(item.dataset.slug)

      item.hidden = !shown
      if (shown) shownCount += 1
      item.querySelector("[data-pin]").className = this.pinClass({ visited: isVisited, active: item.dataset.slug === this.selectedValue })
      item.querySelector("[data-visited-label]").hidden = !isVisited
    })

    this.emptyTarget.hidden = shownCount > 0
    const known = this.placesValue.filter((place) => visited.includes(place.slug)).length
    this.progressTarget.textContent = `${known} of ${this.placesValue.length} explored`
  }

  icon(place, state) {
    return L.divIcon({
      className: "",
      html: `<span class="${this.pinClass(state)}">${place.stop ?? ""}</span>`,
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    })
  }

  pinClass({ visited, active }) {
    return ["map-pin", "shrink-0", visited ? "map-pin-visited" : "", active ? "map-pin-active" : ""].join(" ").trim()
  }

  // Back to the starting view: every place that is showing, fitted to the map.
  resetView() {
    this.fitToVisible()
  }

  fitToVisible() {
    const points = this.placesValue.filter((place) => this.matches(place.kinds)).map((place) => [place.lat, place.lng])
    if (points.length) this.map.fitBounds(points, { padding: [30, 30], maxZoom: 9 })
  }
}
