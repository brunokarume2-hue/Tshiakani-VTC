import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import api from '../services/api'

export default function Rides() {
  const [rides, setRides] = useState([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState({
    status: '',
    startDate: '',
    endDate: ''
  })

  useEffect(() => {
    loadRides()
  }, [filters])

  const loadRides = async () => {
    try {
      const params = new URLSearchParams()
      if (filters.status) params.append('status', filters.status)
      if (filters.startDate) params.append('startDate', filters.startDate)
      if (filters.endDate) params.append('endDate', filters.endDate)

      const response = await api.get(`/admin/rides?${params.toString()}`)
      setRides(response.data.rides)
    } catch (error) {
      console.error('Erreur chargement courses:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      accepted: 'bg-blue-100 text-blue-800',
      inProgress: 'bg-green-100 text-green-800',
      completed: 'bg-gray-100 text-gray-800',
      cancelled: 'bg-red-100 text-red-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  const getStatusLabel = (status) => {
    const labels = {
      pending: 'En attente',
      accepted: 'Accepté',
      inProgress: 'En cours',
      completed: 'Terminé',
      cancelled: 'Annulé'
    }
    return labels[status] || status
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Historique des courses</h1>
      </div>

      {/* Filtres */}
      <div className="bg-white p-6 rounded-xl shadow">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
            <select
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            >
              <option value="">Tous</option>
              <option value="pending">En attente</option>
              <option value="accepted">Accepté</option>
              <option value="inProgress">En cours</option>
              <option value="completed">Terminé</option>
              <option value="cancelled">Annulé</option>
            </select>
          </div>

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

          <div className="flex items-end">
            <button
              onClick={() => setFilters({ status: '', startDate: '', endDate: '' })}
              className="w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
            >
              Réinitialiser
            </button>
          </div>
        </div>
      </div>

      {/* Liste des courses */}
      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conducteur</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Prix</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {rides.map((ride) => (
              <tr key={ride.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 text-sm text-gray-900">
                  #{ride.id}
                </td>
                <td className="px-6 py-4 text-sm">
                  <div>
                    <p className="font-medium">{ride.client?.name || 'N/A'}</p>
                    <p className="text-gray-500 text-xs">{ride.client?.phoneNumber || ''}</p>
                  </div>
                </td>
                <td className="px-6 py-4 text-sm">
                  {ride.driver ? (
                    <div>
                      <p className="font-medium">{ride.driver.name || 'N/A'}</p>
                      <p className="text-gray-500 text-xs">{ride.driver.phoneNumber || ''}</p>
                    </div>
                  ) : (
                    <span className="text-gray-400">-</span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(ride.status)}`}>
                    {getStatusLabel(ride.status)}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm font-semibold text-orange-600">
                  {ride.finalPrice || ride.estimatedPrice} CDF
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {format(new Date(ride.createdAt), 'dd/MM/yyyy HH:mm')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {rides.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucune course trouvée
          </div>
        )}
      </div>
    </div>
  )
}

