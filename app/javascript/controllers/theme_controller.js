import { Controller } from "@hotwired/stimulus"

// Theme switching. localStorage "theme" holds "light" or "dark" to force a
// theme; no entry means auto (follow the system preference). The <head>
// inline script applies the same logic before first paint.
export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.media = matchMedia("(prefers-color-scheme: dark)")
    this.onSystemChange = () => { if (!this.stored) this.apply() }
    this.media.addEventListener("change", this.onSystemChange)
    this.apply()
  }

  disconnect() {
    this.media.removeEventListener("change", this.onSystemChange)
  }

  selectTargetConnected(select) {
    select.value = this.stored || "auto"
  }

  change(event) {
    const choice = event.target.value
    if (choice === "auto") localStorage.removeItem("theme")
    else localStorage.setItem("theme", choice)
    this.apply()
  }

  apply() {
    const dark = this.stored ? this.stored === "dark" : this.media.matches
    document.documentElement.classList.toggle("dark", dark)
    this.syncCharts(dark)
  }

  get stored() {
    return localStorage.getItem("theme")
  }

  // Chart.js reads colors from global defaults when a chart is (re)built.
  syncCharts(dark) {
    if (!window.Chart) return
    window.Chart.defaults.color = dark ? "#9ca3af" : "#4b5563"
    window.Chart.defaults.borderColor = dark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.1)"
    if (!window.Chartkick) return
    Object.values(window.Chartkick.charts).forEach((chart) => {
      if (chart.element?.isConnected) chart.redraw()
    })
  }
}
