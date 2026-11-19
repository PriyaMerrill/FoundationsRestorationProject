import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

const ACTIVE = { radius: 9, color: "#ffffff", weight: 2, fillColor: "#1f7a4a", fillOpacity: 1 }
const PAST = { radius: 7, color: "#64748b", weight: 2, fillColor: "#ffffff", fillOpacity: 1 }

// The expansion map: a year slider that shows which places were active
// in that year and which had already been left behind.
export default class extends Controller {
  static targets = ["canvas", "slider", "year", "status", "playButton"]
  static values = { places: Array }

  connect() {
    this.map = L.map(this.canvasTarget, { scrollWheelZoom: false })
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    this.markers = this.placesValue.map((place) => {
      const marker = L.circleMarker([place.lat, place.lng], ACTIVE)
      const years = place.end ? `${place.start}–${place.end}` : `from ${place.start}`
      const link = document.createElement("a")
      link.href = place.url
      link.textContent = `${place.name} (${years})`
      marker.bindPopup(link)
      return { place, marker }
    })

    this.fit()
    this.show()
  }

  disconnect() {
    this.stop()
    this.map?.remove()
  }

  show() {
    const year = Number(this.sliderTarget.value)
    let active = 0
    let past = 0

    this.markers.forEach(({ place, marker }) => {
      if (place.start > year) {
        marker.remove()
      } else if (place.end && place.end < year) {
        marker.setStyle(PAST).setRadius(PAST.radius).addTo(this.map)
        past += 1
      } else {
        marker.setStyle(ACTIVE).setRadius(ACTIVE.radius).addTo(this.map).bringToFront()
        active += 1
      }
    })

    this.yearTarget.textContent = year
    this.statusTarget.textContent = `In ${year}: ${active} active ${active === 1 ? "place" : "places"}, ${past} left behind.`
  }

  // Back to the start: the first year, and the map showing every place.
  reset() {
    this.stop()
    this.sliderTarget.value = this.sliderTarget.min
    this.fit()
    this.show()
  }

  fit() {
    if (this.placesValue.length) {
      this.map.fitBounds(this.placesValue.map((place) => [place.lat, place.lng]), { padding: [30, 30] })
    }
  }

  togglePlay() {
    this.timer ? this.stop() : this.play()
  }

  play() {
    if (Number(this.sliderTarget.value) >= Number(this.sliderTarget.max)) this.sliderTarget.value = this.sliderTarget.min
    this.show()
    this.playButtonTarget.setAttribute("aria-pressed", "true")
    this.playButtonTarget.textContent = "Pause"

    this.timer = setInterval(() => {
      if (Number(this.sliderTarget.value) >= Number(this.sliderTarget.max)) return this.stop()
      this.sliderTarget.value = Number(this.sliderTarget.value) + 1
      this.show()
    }, 900)
  }

  stop() {
    clearInterval(this.timer)
    this.timer = null
    if (this.hasPlayButtonTarget) {
      this.playButtonTarget.setAttribute("aria-pressed", "false")
      this.playButtonTarget.textContent = "Play"
    }
  }
}
