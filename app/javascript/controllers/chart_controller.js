import { Controller } from "@hotwired/stimulus"
import "chart.js"

// The self-contained Chart.js build adds itself to the page as window.Chart.
const Chart = window.Chart

const MARK = "#1f7a4a"        // the one series colour, checked for contrast and colour-blind safety
const MARK_ACTIVE = "#14532d"
const INK = "#334155"
const GRID = "#e7e5e4"

// Draws one chart from a list of points. Choosing a bar or point shows
// what it counts, with links to the records behind it.
export default class extends Controller {
  static targets = ["canvas", "detail", "hint"]
  static values = { type: String, unit: String, points: Array }

  connect() {
    if (!this.hasCanvasTarget) return

    const horizontal = this.typeValue === "hbar"
    const line = this.typeValue === "line"
    const few = this.pointsValue.length <= 6
    const number = (value) => Number(value).toLocaleString("en-US")

    Chart.defaults.font.family = '"Source Sans 3", ui-sans-serif, system-ui, sans-serif'
    Chart.defaults.font.size = 14
    Chart.defaults.color = INK

    this.chart = new Chart(this.canvasTarget, {
      type: line ? "line" : "bar",
      data: {
        // With only a few bars, show every label and wrap long ones onto two lines.
        labels: this.pointsValue.map((point) => (few && !horizontal ? point.label.split(" ") : point.label)),
        datasets: [{
          label: this.unitValue,
          data: this.pointsValue.map((point) => point.value),
          backgroundColor: MARK,
          hoverBackgroundColor: MARK_ACTIVE,
          borderColor: MARK,
          borderWidth: line ? 2 : 0,
          borderRadius: 4,
          maxBarThickness: 44,
          pointRadius: 4,
          pointHoverRadius: 7,
          pointHitRadius: 16,
          pointBackgroundColor: MARK,
          pointBorderColor: "#ffffff",
          pointBorderWidth: 2,
          tension: 0
        }]
      },
      options: {
        indexAxis: horizontal ? "y" : "x",
        responsive: true,
        maintainAspectRatio: false,
        animation: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? false : { duration: 300 },
        interaction: { mode: "index", intersect: false, axis: horizontal ? "y" : "x" },
        onClick: (_event, elements) => { if (elements.length) this.showDetail(elements[0].index) },
        onHover: (event, elements) => { event.native.target.style.cursor = elements.length ? "pointer" : "default" },
        plugins: {
          legend: { display: false },
          tooltip: {
            displayColors: false,
            callbacks: {
              title: (items) => this.pointsValue[items[0].dataIndex].label,
              label: (item) => `${number(item.parsed[horizontal ? "x" : "y"])} ${this.unitValue}`
            }
          }
        },
        scales: {
          [horizontal ? "x" : "y"]: {
            beginAtZero: true,
            grid: { color: GRID },
            border: { display: false },
            ticks: { precision: 0, callback: (value) => number(value), maxTicksLimit: 6 }
          },
          [horizontal ? "y" : "x"]: {
            grid: { display: false },
            ticks: { autoSkip: !horizontal && !few, maxRotation: 0 }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  showDetail(index) {
    const point = this.pointsValue[index]
    const detail = this.detailTarget
    detail.replaceChildren()

    const summary = document.createElement("p")
    summary.className = "font-semibold"
    summary.textContent = `${point.label}: ${point.detail}`
    detail.append(summary)

    if (point.records.length) {
      const list = document.createElement("ul")
      list.className = "mt-2 flex flex-wrap gap-2"
      point.records.forEach((record) => {
        const item = document.createElement("li")
        const link = document.createElement("a")
        link.href = record.url
        link.className = "record-link"

        const type = document.createElement("span")
        type.className = "text-xs font-semibold uppercase tracking-wide text-gold-700"
        type.textContent = record.type

        const label = document.createElement("span")
        label.className = "font-semibold"
        label.textContent = record.label

        link.append(type, label)
        item.append(link)
        list.append(item)
      })
      detail.append(list)
    }

    detail.hidden = false
    if (this.hasHintTarget) this.hintTarget.hidden = true
  }
}
