import { useEffect, useState } from 'react'
import { Line, Doughnut } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
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
  ArcElement,
  Title,
  Tooltip,
  Legend
)

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      // L'intercepteur ajoute automatiquement la clé API
      const response = await api.get('/admin/stats')
      setStats(response.data)
    } catch (error) {
      console.error('Erreur chargement stats:', error)
      // En cas d'erreur, utiliser des données par défaut
      setStats({
        users: {
          total: 0,
          drivers: 0,
          activeDrivers: 0
        },
        rides: {
          total: 0,
          today: 0,
          completed: 0,
          last7Days: [0, 0, 0, 0, 0, 0, 0]
        },
        revenue: {
          total: 0
        }
      })
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  if (!stats) {
    return <div className="text-center py-12 text-red-600">Erreur de chargement</div>
  }

  // Utiliser les vraies données des 7 derniers jours
  const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
  const ridesData = {
    labels: dayLabels,
    datasets: [{
      label: 'Courses',
      data: stats.rides.last7Days || [0, 0, 0, 0, 0, 0, 0],
      borderColor: 'rgb(34, 197, 94)',
      backgroundColor: 'rgba(34, 197, 94, 0.1)',
      tension: 0.4
    }]
  }

  const usersData = {
    labels: ['Clients', 'Conducteurs', 'Admins'],
    datasets: [{
      data: [
        stats.users.total - stats.users.drivers,
        stats.users.drivers,
        1
      ],
      backgroundColor: [
        'rgba(34, 197, 94, 0.8)',
        'rgba(255, 107, 0, 0.8)',
        'rgba(107, 114, 128, 0.8)'
      ]
    }]
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Vue d'ensemble</h1>

      {/* Statistiques principales */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Utilisateurs totaux"
          value={stats.users.total}
          icon="👥"
          color="green"
        />
        <StatCard
          title="Conducteurs actifs"
          value={stats.users.activeDrivers}
          icon="🏍️"
          color="orange"
        />
        <StatCard
          title="Courses aujourd'hui"
          value={stats.rides.today}
          icon="🚗"
          color="blue"
        />
        <StatCard
          title="Revenus totaux"
          value={`${(stats.revenue.total / 1000).toFixed(0)}K CDF`}
          icon="💰"
          color="green"
        />
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Évolution des courses</h2>
          <Line data={ridesData} options={{ responsive: true }} />
        </div>

        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Répartition des utilisateurs</h2>
          <Doughnut data={usersData} options={{ responsive: true }} />
        </div>
      </div>

      {/* Détails supplémentaires */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Courses totales</h3>
          <p className="text-3xl font-bold text-gray-800">{stats.rides.total}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Courses terminées</h3>
          <p className="text-3xl font-bold text-green-600">{stats.rides.completed}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <h3 className="font-semibold text-gray-700 mb-2">Taux de complétion</h3>
          <p className="text-3xl font-bold text-orange-600">
            {stats.rides.total > 0 
              ? ((stats.rides.completed / stats.rides.total) * 100).toFixed(1)
              : 0}%
          </p>
        </div>
      </div>
    </div>
  )
}

function StatCard({ title, value, icon, color }) {
  const colorClasses = {
    green: 'bg-green-50 text-green-600',
    orange: 'bg-orange-50 text-orange-600',
    blue: 'bg-blue-50 text-blue-600'
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

