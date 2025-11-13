import { useEffect, useState } from 'react'
import { Line, Bar, Doughnut } from 'react-chartjs-2'
import { format } from 'date-fns'
import api from '../services/api'

// Fonction utilitaire pour formater les montants
const formatCurrency = (amount) => {
  const num = parseFloat(amount || 0)
  if (num >= 1000000) {
    return `${(num / 1000000).toFixed(1)}M CDF`
  } else if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}K CDF`
  }
  return `${num.toLocaleString('fr-FR')} CDF`
}

export default function Finance() {
  const [stats, setStats] = useState(null)
  const [transactions, setTransactions] = useState([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState({
    startDate: '',
    endDate: '',
    type: ''
  })

  useEffect(() => {
    loadData()
  }, [filters])

  const loadData = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (filters.startDate) params.append('startDate', filters.startDate)
      if (filters.endDate) params.append('endDate', filters.endDate)
      if (filters.type) params.append('type', filters.type)

      const [statsResponse, transactionsResponse] = await Promise.all([
        api.get(`/admin/finance/stats?${params.toString()}`),
        api.get(`/admin/finance/transactions?${params.toString()}`)
      ])

      setStats(statsResponse.data || {
        totalRevenue: 0,
        totalCommissions: 0,
        netRevenue: 0,
        pendingWithdrawals: 0,
        dailyRevenue: [],
        topDrivers: []
      })
      setTransactions(transactionsResponse.data?.transactions || [])
    } catch (error) {
      console.error('Erreur chargement données:', error)
      // Données par défaut en cas d'erreur
      setStats({
        totalRevenue: 0,
        totalCommissions: 0,
        netRevenue: 0,
        pendingWithdrawals: 0,
        dailyRevenue: [],
        topDrivers: []
      })
      setTransactions([])
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

  // Données pour les graphiques
  const revenueData = {
    labels: stats.dailyRevenue?.map(d => {
      try {
        return format(new Date(d.date), 'dd/MM')
      } catch (e) {
        return d.date || ''
      }
    }) || [],
    datasets: [{
      label: 'Revenus (CDF)',
      data: stats.dailyRevenue?.map(d => parseFloat(d.amount || 0)) || [],
      borderColor: 'rgb(34, 197, 94)',
      backgroundColor: 'rgba(34, 197, 94, 0.1)',
      tension: 0.4
    }]
  }

  const commissionData = {
    labels: ['Revenus totaux', 'Commissions conducteurs', 'Revenus nets'],
    datasets: [{
      data: [
        stats.totalRevenue || 0,
        stats.totalCommissions || 0,
        (stats.totalRevenue || 0) - (stats.totalCommissions || 0)
      ],
      backgroundColor: [
        'rgba(34, 197, 94, 0.8)',
        'rgba(255, 107, 0, 0.8)',
        'rgba(59, 130, 246, 0.8)'
      ]
    }]
  }

  const driverEarningsData = {
    labels: stats.topDrivers?.map(d => d.name) || [],
    datasets: [{
      label: 'Revenus (CDF)',
      data: stats.topDrivers?.map(d => d.earnings) || [],
      backgroundColor: 'rgba(59, 130, 246, 0.8)'
    }]
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion financière</h1>
      </div>

      {/* Filtres */}
      <div className="bg-white p-6 rounded-xl shadow">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date début</label>
            <input
              type="date"
              value={filters.startDate}
              onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date fin</label>
            <input
              type="date"
              value={filters.endDate}
              onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Type</label>
            <select
              value={filters.type}
              onChange={(e) => setFilters({ ...filters, type: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            >
              <option value="">Tous</option>
              <option value="revenue">Revenus</option>
              <option value="commission">Commissions</option>
              <option value="withdrawal">Retraits</option>
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={() => setFilters({ startDate: '', endDate: '', type: '' })}
              className="w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
            >
              Réinitialiser
            </button>
          </div>
        </div>
      </div>

      {/* Statistiques principales */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Revenus totaux"
          value={formatCurrency(stats.totalRevenue || 0)}
          icon="💰"
          color="green"
        />
        <StatCard
          title="Commissions"
          value={formatCurrency(stats.totalCommissions || 0)}
          icon="💳"
          color="orange"
        />
        <StatCard
          title="Revenus nets"
          value={formatCurrency((stats.totalRevenue || 0) - (stats.totalCommissions || 0))}
          icon="📈"
          color="blue"
        />
        <StatCard
          title="Retraits en attente"
          value={formatCurrency(stats.pendingWithdrawals || 0)}
          icon="⏳"
          color="yellow"
        />
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Évolution des revenus</h2>
          {stats.dailyRevenue && stats.dailyRevenue.length > 0 && stats.dailyRevenue.some(d => d.amount > 0) ? (
            <Line data={revenueData} options={{ 
              responsive: true,
              plugins: {
                legend: {
                  display: true
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      return `Revenus: ${context.parsed.y.toLocaleString('fr-FR')} CDF`
                    }
                  }
                }
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {
                    callback: function(value) {
                      return value.toLocaleString('fr-FR') + ' CDF'
                    }
                  }
                }
              }
            }} />
          ) : (
            <div className="text-center py-12 text-gray-500">Aucune donnée disponible</div>
          )}
        </div>

        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Répartition financière</h2>
          {stats.totalRevenue > 0 ? (
            <Doughnut data={commissionData} options={{ 
              responsive: true,
              plugins: {
                legend: {
                  display: true,
                  position: 'bottom'
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      const label = context.label || ''
                      const value = context.parsed || 0
                      return `${label}: ${value.toLocaleString('fr-FR')} CDF`
                    }
                  }
                }
              }
            }} />
          ) : (
            <div className="text-center py-12 text-gray-500">Aucune donnée disponible</div>
          )}
        </div>
      </div>

      {/* Top conducteurs */}
      {stats.topDrivers && stats.topDrivers.length > 0 && (
        <div className="bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-semibold mb-4">Top 10 conducteurs (revenus)</h2>
          <Bar data={driverEarningsData} options={{ 
            responsive: true,
            plugins: {
              legend: {
                display: false
              },
              tooltip: {
                callbacks: {
                  label: function(context) {
                    return `Revenus: ${context.parsed.y.toLocaleString('fr-FR')} CDF`
                  }
                }
              }
            },
            scales: {
              y: {
                beginAtZero: true,
                ticks: {
                  callback: function(value) {
                    return value.toLocaleString('fr-FR') + ' CDF'
                  }
                }
              }
            }
          }} />
        </div>
      )}

      {/* Transactions */}
      <div className="bg-white rounded-xl shadow overflow-hidden">
        <div className="p-6 border-b">
          <h2 className="text-xl font-semibold">Transactions récentes</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conducteur</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {transactions.map((transaction) => (
                <tr key={transaction.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {format(new Date(transaction.createdAt), 'dd/MM/yyyy HH:mm')}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      transaction.type === 'revenue' ? 'bg-green-100 text-green-800' :
                      transaction.type === 'commission' ? 'bg-orange-100 text-orange-800' :
                      'bg-blue-100 text-blue-800'
                    }`}>
                      {transaction.type === 'revenue' ? 'Revenu' :
                       transaction.type === 'commission' ? 'Commission' :
                       'Retrait'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm">
                    {transaction.driver?.name || 'N/A'}
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold">
                    {parseFloat(transaction.amount || 0).toLocaleString('fr-FR')} CDF
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      transaction.status === 'completed' ? 'bg-green-100 text-green-800' :
                      transaction.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-red-100 text-red-800'
                    }`}>
                      {transaction.status === 'completed' ? 'Complété' :
                       transaction.status === 'pending' ? 'En attente' :
                       'Échoué'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {transactions.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              Aucune transaction trouvée
            </div>
          )}
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
    yellow: 'bg-yellow-50 text-yellow-600'
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

