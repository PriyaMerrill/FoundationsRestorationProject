import { Controller } from "@hotwired/stimulus"
import "chart.js"

// The self-contained Chart.js build adds itself to the page as window.Chart.
const Chart = window.Chart

const MARK = "#1f7a4a" // used when a chart has a single colour
const INK = "#334155"
const GRID = "#e7e5e4"

// Draws one chart from a list of points. Choosing a bar or point shows
// what it counts, with links to the records behind it.
//
// A chart is coloured one of three ways:
//   one colour throughout (the default);
//   a colour per bar, when points carry their own colour;
//   several coloured parts stacked in each bar, when "series" is given.
export default class extends Controller {
  static targets = ["canvas", "detail", "hint"]
  static values = { type: String, unit: String, points: Array, series: Array }

  connect() {
    if (!this.hasCanvasTarget) return

    const horizontal = this.typeValue === "hbar"
    const line = this.typeValue === "line"
    const stacked = this.seriesValue.length > 0
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
        datasets: stacked ? this.stackedDatasets() : [this.singleDataset(line)]
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
          legend: { display: false }, // the key is written out above the chart instead
          tooltip: {
            displayColors: stacked,
            filter: (item) => !stacked || item.parsed.y > 0,
            callbacks: {
              title: (items) => (items.length ? this.pointsValue[items[0].dataIndex].label : ""),
              label: (item) => {
                const value = number(item.parsed[horizontal ? "x" : "y"])
                return stacked ? `${item.dataset.label}: ${value}` : `${value} ${this.unitValue}`
              },
              footer: (items) => (stacked && items.length ? `Total: ${number(this.pointsValue[items[0].dataIndex].value)} ${this.unitValue}` : "")
            }
          }
        },
        scales: {
          [horizontal ? "x" : "y"]: {
            stacked,
            beginAtZero: true,
            grid: { color: (context) => (context.tick.value === 0 ? "#94a3b8" : GRID) },
            border: { display: false },
            ticks: { precision: 0, callback: (value) => number(value), maxTicksLimit: 6 }
          },
          [horizontal ? "y" : "x"]: {
            stacked,
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

  singleDataset(line) {
    const colors = this.pointsValue.map((point) => point.color || MARK)
    const dataset = {
      label: this.unitValue,
      data: this.pointsValue.map((point) => point.value),
      backgroundColor: colors,
      borderRadius: 4,
      maxBarThickness: 44
    }
    if (!line) return dataset

    // A line with a soft fill beneath it.
    return Object.assign(dataset, {
      borderColor: MARK,
      borderWidth: 2.5,
      fill: true,
      backgroundColor: (context) => {
        const area = context.chart.chartArea
        if (!area) return "rgba(31, 122, 74, 0.15)"
        const gradient = context.chart.ctx.createLinearGradient(0, area.top, 0, area.bottom)
        gradient.addColorStop(0, "rgba(31, 122, 74, 0.35)")
        gradient.addColorStop(1, "rgba(31, 122, 74, 0.02)")
        return gradient
      },
      pointRadius: 4,
      pointHoverRadius: 7,
      pointHitRadius: 16,
      pointBackgroundColor: MARK,
      pointBorderColor: "#ffffff",
      pointBorderWidth: 2,
      tension: 0.25
    })
  }

  // One dataset per coloured part, with a thin white gap between parts.
  stackedDatasets() {
    return this.seriesValue.map((part) => ({
      label: part.name,
      data: part.values,
      backgroundColor: part.color,
      borderColor: "#ffffff",
      borderWidth: { top: 2, right: 0, bottom: 0, left: 0 },
      borderRadius: 3,
      maxBarThickness: 44
    }))
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
