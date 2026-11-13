import { Chart, registerables } from './chart.js';
Chart.register(...registerables);
"use strict";
const chartData = document.getElementById('chart-data');
const canvas = document.getElementById('annual-chart');
if (chartData && canvas && typeof Chart !== 'undefined') {
  const months = JSON.parse(chartData.textContent);
  new Chart(canvas, {
    type: 'bar',
    data: { labels: months.map(m => m.name), datasets: [
      { label: 'Receitas', data: months.map(m => m.income / 100), backgroundColor: '#30d988', borderRadius: 4 },
      { label: 'Despesas', data: months.map(m => m.expense / 100), backgroundColor: '#6d7486', borderRadius: 4 }
    ]},
    options: { responsive: true, animation: !matchMedia('(prefers-reduced-motion: reduce)').matches,
      plugins: { legend: { labels: { color: '#a3a8b7' } }, tooltip: { callbacks: {
        label: context => context.dataset.label + ': ' + new Intl.NumberFormat('pt-BR', {style: 'currency', currency: 'BRL'}).format(context.parsed.y)
      }}}, scales: { y: { beginAtZero: true, ticks: {color: '#a3a8b7'}, grid: {color: '#ffffff10'} }, x: {ticks: {color: '#a3a8b7'}, grid: {display: false}} }
    }
  });
}
