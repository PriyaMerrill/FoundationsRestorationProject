import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// A small, still map with one pin, used as a picture of where a place is.
// It cannot be dragged or zoomed; the card it sits in is the link.
export default class extends Controller {
  static values = { lat: Number, lng: Number, zoom: { type: Number, default: 6 } }

  connect() {
    const position = [this.latValue, this.lngValue]

    this.map = L.map(this.element, {
      zoomControl: false, dragging: false, scrollWheelZoom: false, doubleClickZoom: false,
      boxZoom: false, keyboard: false, touchZoom: false, tap: false
    }).setView(position, this.zoomValue)

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    L.marker(position, {
      interactive: false, keyboard: false,
      icon: L.divIcon({ className: "", html: '<span class="map-pin map-pin-visited"></span>', iconSize: [32, 32], iconAnchor: [16, 16] })
    }).addTo(this.map)
  }

  disconnect() {
    this.map?.remove()
  }
}
