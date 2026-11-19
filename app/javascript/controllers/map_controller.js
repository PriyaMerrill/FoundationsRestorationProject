import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import { visitedPlaces } from "visited_places"

// The Road Trip map. Draws a marker for each place, opens a place in the
// slide-over panel when its marker is chosen, filters by kind of place,
// shows the road-trip route, and marks the places a visitor has explored.
export default class extends Controller {
  static targets = [
    "canvas", "filter", "item", "list", "routeButton", "progress", "empty",
    "trip", "tripNumber", "tripCount", "tripName", "tripFacts", "tripLeg", "tripStatus", "tripPrevious", "tripNext"
  ]
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

    this.addResetControl()

    this.stops = this.placesValue.filter((place) => place.stop).sort((a, b) => a.stop - b.stop)
    this.route = L.polyline(this.stops.map((place) => [place.lat, place.lng]), {
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
    this.selectedValue = this.touring ? this.stops[this.stopIndex].slug : ""
    this.refresh()
  }

  focusOn(slug) {
    this.selectedValue = slug
    const place = this.placesValue.find((candidate) => candidate.slug === slug)
    if (place) this.map.setView([place.lat, place.lng], Math.max(this.map.getZoom(), 7))

    // During a trip, opening a place from the list or map moves the trip there.
    const index = this.stops.findIndex((stop) => stop.slug === slug)
    if (this.touring && index >= 0) this.stopIndex = index

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

  // --- the road trip: travel the route one stop at a time ---

  startTrip() {
    this.touring = true
    this.kind = ""
    this.filterTargets.forEach((button) => button.setAttribute("aria-pressed", button.dataset.kind === ""))

    this.route.addTo(this.map)
    this.routeButtonTarget.hidden = true // the trip bar has its own "Finish the trip" button
    this.tripTarget.hidden = false

    this.goToStop(0)
    this.tripNameTarget.focus({ preventScroll: true })
  }

  endTrip() {
    this.touring = false
    this.route.remove()
    this.routeButtonTarget.hidden = false
    this.tripTarget.hidden = true

    this.selectedValue = ""
    this.refresh()
    this.fitToVisible()
  }

  nextStop() {
    if (this.stopIndex < this.stops.length - 1) this.goToStop(this.stopIndex + 1)
  }

  previousStop() {
    if (this.stopIndex > 0) this.goToStop(this.stopIndex - 1)
  }

  // Travels to a stop: the map glides there and the trip bar describes it.
  goToStop(index) {
    this.stopIndex = index
    const stop = this.stops[index]
    this.selectedValue = stop.slug

    const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.map.flyTo([stop.lat, stop.lng], 8, { animate: !still, duration: 1.4 })
    this.refresh()
  }

  readAboutStop() {
    this.openPlace(this.stops[this.stopIndex])
  }

  drawTrip(visited) {
    if (!this.touring) return

    const stop = this.stops[this.stopIndex]
    const last = this.stopIndex === this.stops.length - 1
    const explored = visited.includes(stop.slug)

    this.tripNumberTarget.textContent = stop.stop
    this.tripCountTarget.textContent = `Stop ${this.stopIndex + 1} of ${this.stops.length}`
    this.tripNameTarget.textContent = stop.name
    this.tripFactsTarget.textContent = stop.facts
    this.tripLegTarget.textContent = stop.leg ? `About ${stop.leg.miles.toLocaleString("en-US")} miles from ${stop.leg.from}` : "The journey begins here."

    this.tripStatusTarget.textContent = explored ? "✓ Explored" : "Not explored yet"
    this.tripStatusTarget.classList.toggle("trip-status-explored", explored)

    this.tripPreviousTarget.disabled = this.stopIndex === 0
    this.tripNextTarget.hidden = last
    if (!last) this.tripNextTarget.textContent = `Next stop: ${this.stops[this.stopIndex + 1].name} →`
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
      const isActive = item.dataset.slug === this.selectedValue
      item.classList.toggle("is-visited", isVisited)
      item.classList.toggle("is-active", isActive)
      item.querySelector("[data-visited-label]").hidden = !isVisited
      if (isActive) this.showInList(item)
    })

    this.drawTrip(visited)

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

  // Scrolls the list of places, where it has its own scrollbar, so the chosen place shows.
  showInList(item) {
    const list = this.listTarget
    if (list.scrollHeight <= list.clientHeight) return

    const top = item.offsetTop - list.offsetTop
    if (top < list.scrollTop || top + item.offsetHeight > list.scrollTop + list.clientHeight) {
      list.scrollTo({ top: top - 8, behavior: "smooth" })
    }
  }

  // A small button under the zoom buttons that returns the map to its starting view.
  addResetControl() {
    const control = L.control({ position: "topleft" })
    control.onAdd = () => {
      const bar = L.DomUtil.create("div", "leaflet-bar")
      const button = L.DomUtil.create("button", "map-reset", bar)
      button.type = "button"
      button.title = "Reset map view"
      button.setAttribute("aria-label", "Reset map view")
      button.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.700"/><path d="M3 4v5h5"/></svg>'
      L.DomEvent.disableClickPropagation(bar)
      L.DomEvent.on(button, "click", () => this.resetView())
      return bar
    }
    control.addTo(this.map)
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
