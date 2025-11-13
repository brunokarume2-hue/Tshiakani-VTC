import { useEffect, useState } from 'react'
import { Line, Bar, Doughnut } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import api from '../services/api'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
)

export default function AgentPrincipal() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    loadStats()
    // Rafraîchir toutes les 30 secondes
    const interval = setInterval(loadStats, 30000)
    return () => clearInterval(interval)
  }, [])

  const loadStats = async () => {
    try {
      setError(null)
      const response = await api.get('/admin/agent-principal/stats')
      setStats(response.data)
    } catch (error) {
      console.error('Erreur chargement stats agent principal:', error)
      setError(error.response?.data?.error || 'Erreur de chargement')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
        <p className="mt-4 text-gray-600">Chargement des métriques...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 max-w-md mx-auto">
          <p className="text-red-600 font-semibold">Erreur</p>
          <p className="text-red-500 text-sm mt-2">{error}</p>
          <button
            onClick={loadStats}
            className="mt-4 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Réessayer
          </button>
        </div>
      </div>
    )
  }

  if (!stats) {
    return <div className="text-center py-12 text-red-600">Aucune donnée disponible</div>
  }

  // Préparer les données pour les graphiques
  const performanceData = {
    labels: stats.performance.last7Days.map(day => {
      const date = new Date(day.date)
      return date.toLocaleDateString('fr-FR', { weekday: 'short' })
    }),
    datasets: [
      {
        label: 'Taux de matching (%)',
        data: stats.performance.last7Days.map(day => day.matchingRate),
        borderColor: 'rgb(34, 197, 94)',
        backgroundColor: 'rgba(34, 197, 94, 0.1)',
        tension: 0.4,
        yAxisID: 'y'
      },
      {
        label: 'Taux de complétion (%)',
        data: stats.performance.last7Days.map(day => day.completionRate),
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        tension: 0.4,
        yAxisID: 'y'
      }
    ]
  }

  const ridesByDayData = {
    labels: stats.performance.last7Days.map(day => {
      const date = new Date(day.date)
      return date.toLocaleDateString('fr-FR', { weekday: 'short' })
    }),
    datasets: [
      {
        label: 'Courses créées',
        data: stats.performance.last7Days.map(day => day.total),
        backgroundColor: 'rgba(34, 197, 94, 0.8)'
      },
      {
        label: 'Courses avec conducteur',
        data: stats.performance.last7Days.map(day => day.withDriver),
        backgroundColor: 'rgba(59, 130, 246, 0.8)'
      },
      {
        label: 'Courses terminées',
        data: stats.performance.last7Days.map(day => day.completed),
        backgroundColor: 'rgba(251, 191, 36, 0.8)'
      }
    ]
  }

  const matchingStatusData = {
    labels: stats.matching.statsByStatus.map(s => {
      const statusLabels = {
        'pending': 'En attente',
        'accepted': 'Accepté',
        'inProgress': 'En cours',
        'completed': 'Terminé',
        'cancelled': 'Annulé'
      }
      return statusLabels[s.status] || s.status
    }),
    datasets: [{
      data: stats.matching.statsByStatus.map(s => parseInt(s.count)),
      backgroundColor: [
        'rgba(251, 191, 36, 0.8)',
        'rgba(59, 130, 246, 0.8)',
        'rgba(168, 85, 247, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(239, 68, 68, 0.8)'
      ]
    }]
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-800">Agent Principal</h1>
          <p className="text-gray-600 mt-1">Métriques et performances en temps réel</p>
        </div>
        <button
          onClick={loadStats}
          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
        >
          <span>🔄</span>
          <span>Actualiser</span>
        </button>
      </div>

      {/* Statistiques principales */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Courses créées (24h)"
          value={stats.matching.totalRides24h}
          icon="🚗"
          color="blue"
        />
        <StatCard
          title="Taux de matching"
          value={`${stats.matching.matchingRate.toFixed(1)}%`}
          icon="🎯"
          color="green"
        />
        <StatCard
          title="Temps moyen matching"
          value={`${stats.matching.averageMatchingTimeSeconds.toFixed(1)}s`}
          icon="⏱️"
          color="orange"
        />
        <StatCard
          title="Conducteurs actifs"
          value={stats.performance.activeDrivers}
          icon="👥"
          color="purple"
        />
      </div>

      {/* Statistiques générales */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Courses avec conducteur</h3>
          <p className="text-3xl font-bold text-green-600">{stats.matching.ridesWithDriver}</p>
          <p className="text-sm text-gray-500 mt-2">
            {stats.matching.totalRides24h > 0
              ? `${((stats.matching.ridesWithDriver / stats.matching.totalRides24h) * 100).toFixed(1)}% du total`
              : '0% du total'}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Courses sans conducteur</h3>
          <p className="text-3xl font-bold text-orange-600">{stats.matching.ridesWithoutDriver}</p>
          <p className="text-sm text-gray-500 mt-2">
            {stats.matching.totalRides24h > 0
              ? `${((stats.matching.ridesWithoutDriver / stats.matching.totalRides24h) * 100).toFixed(1)}% du total`
              : '0% du total'}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Revenus (24h)</h3>
          <p className="text-3xl font-bold text-green-600">
            {Math.round(stats.pricing.totalRevenue24h).toLocaleString()} CDF
          </p>
          <p className="text-sm text-gray-500 mt-2">
            Moyenne: {Math.round(stats.pricing.averageFinalPrice).toLocaleString()} CDF
          </p>
        </div>
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Performance des 7 derniers jours</h2>
          <Line 
            data={performanceData} 
            options={{ 
              responsive: true,
              plugins: {
                legend: {
                  position: 'top'
                },
                title: {
                  display: false
                }
              },
              scales: {
                y: {
                  beginAtZero: true,
                  max: 100,
                  ticks: {
                    callback: function(value) {
                      return value + '%'
                    }
                  }
                }
              }
            }} 
          />
        </div>

        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Répartition par statut (24h)</h2>
          {stats.matching.statsByStatus.length > 0 ? (
            <Doughnut 
              data={matchingStatusData} 
              options={{ 
                responsive: true,
                plugins: {
                  legend: {
                    position: 'right'
                  }
                }
              }} 
            />
          ) : (
            <p className="text-gray-500 text-center py-8">Aucune donnée disponible</p>
          )}
        </div>
      </div>

      {/* Graphique des courses par jour */}
      <div className="bg-white p-6 rounded-xl shadow">
        <h2 className="text-xl font-semibold mb-4">Courses par jour (7 derniers jours)</h2>
        <Bar 
          data={ridesByDayData} 
          options={{ 
            responsive: true,
            plugins: {
              legend: {
                position: 'top'
              }
            },
            scales: {
              y: {
                beginAtZero: true
              }
            }
          }} 
        />
      </div>

      {/* Statistiques détaillées */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="text-lg font-semibold mb-4">Statistiques générales</h3>
          <div className="space-y-3">
            <StatRow label="Conducteurs totaux" value={stats.general.drivers.total} />
            <StatRow label="Conducteurs actifs" value={stats.general.drivers.active} />
            <StatRow label="Clients totaux" value={stats.general.clients.total} />
            <StatRow label="Courses totales" value={stats.general.rides.total} />
            <StatRow label="Courses aujourd'hui" value={stats.general.rides.today} />
            <StatRow label="Courses terminées" value={stats.general.rides.completed} />
            <StatRow 
              label="Revenus totaux" 
              value={`${Math.round(stats.general.revenue.total).toLocaleString()} CDF`} 
            />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="text-lg font-semibold mb-4">Statistiques de pricing</h3>
          <div className="space-y-3">
            <StatRow 
              label="Prix moyen estimé" 
              value={`${Math.round(stats.pricing.averageEstimatedPrice).toLocaleString()} CDF`} 
            />
            <StatRow 
              label="Prix moyen final" 
              value={`${Math.round(stats.pricing.averageFinalPrice).toLocaleString()} CDF`} 
            />
            <StatRow 
              label="Revenus 24h" 
              value={`${Math.round(stats.pricing.totalRevenue24h).toLocaleString()} CDF`} 
            />
            <div className="pt-3 border-t">
              <p className="text-sm text-gray-500">
                Dernière mise à jour: {new Date(stats.timestamp).toLocaleString('fr-FR')}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ title, value, icon, color }) {
  const colorClasses = {
    green: 'bg-green-50 text-green-600',
    orange: 'bg-orange-50 text-orange-600',
    blue: 'bg-blue-50 text-blue-600',
    purple: 'bg-purple-50 text-purple-600'
  }

  return (
    <div className="bg-white p-6 rounded-xl shadow">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600 mb-1">{title}</p>
          <p className="text-3xl font-bold text-gray-800">{value}</p>
        </div>
        <div className={`w-16 h-16 rounded-full flex items-center justify-center text-3xl ${colorClasses[color]}`}>
          {icon}
        </div>
      </div>
    </div>
  )
}

function StatRow({ label, value }) {
  return (
    <div className="flex justify-between items-center">
      <span className="text-gray-600">{label}</span>
      <span className="font-semibold text-gray-800">{value}</span>
    </div>
  )
}

