import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static targets = ["monthly", "categories"]

  static values = {
    monthly: Array,
    categories: Array
  }

  connect() {
    this.renderMonthlyChart()
    this.renderCategoryChart()
  }

  disconnect() {
    this.monthlyChart?.destroy()
    this.categoryChart?.destroy()
  }

  renderMonthlyChart() {
    if (!this.hasMonthlyTarget) return

    const data = this.monthlyValue

    this.monthlyChart = new Chart(this.monthlyTarget, {
      type: "bar",

      data: {
        labels: data.map(item => item.month),

        datasets: [
          {
            label: "Receitas",
            data: data.map(item => item.income),
            backgroundColor: "#30d988"
          },
          {
            label: "Despesas",
            data: data.map(item => item.expense),
            backgroundColor: "#f87171"
          }
        ]
      },

      options: {
        responsive: true,
        maintainAspectRatio: false,

        plugins: {
          legend: {
            labels: {
              color: "#a3a8b7"
            }
          }
        },

        scales: {
          x: {
            ticks: {
              color: "#a3a8b7"
            },

            grid: {
              color: "rgba(255,255,255,0.04)"
            }
          },

          y: {
            beginAtZero: true,

            ticks: {
              color: "#a3a8b7"
            },

            grid: {
              color: "rgba(255,255,255,0.04)"
            }
          }
        }
      }
    })
  }

  renderCategoryChart() {
    if (!this.hasCategoriesTarget) return

    const data = this.categoriesValue

    if (data.length === 0) return

    this.categoryChart = new Chart(this.categoriesTarget, {
      type: "doughnut",

      data: {
        labels: data.map(item => item.name),

        datasets: [
          {
            data: data.map(item => item.value),
            backgroundColor: [
              "#30d988",
              "#f87171",
              "#f5b731",
              "#38bdf8",
              "#f472b6",
              "#a78bfa",
              "#fb923c",
              "#2dd4bf"
            ],
            borderWidth: 0
          }
        ]
      },

      options: {
        responsive: true,
        maintainAspectRatio: false,

        cutout: "68%",

        plugins: {
          legend: {
            position: "bottom",

            labels: {
              color: "#a3a8b7",
              padding: 18
            }
          }
        }
      }
    })
  }
}