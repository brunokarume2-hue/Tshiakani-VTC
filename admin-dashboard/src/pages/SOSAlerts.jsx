import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import api from '../services/api'

export default function SOSAlerts() {
  const [alerts, setAlerts] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('')

  useEffect(() => {
    loadAlerts()
  }, [filter])

  const loadAlerts = async () => {
    try {
      const params = filter ? `?status=${filter}` : ''
      const response = await api.get(`/admin/sos${params}`)
      setAlerts(response.data)
    } catch (error) {
      console.error('Erreur chargement alertes SOS:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleResolve = async (sosId) => {
    if (!window.confirm('Marquer cette alerte comme résolue ?')) {
      return
    }

    try {
      await api.patch(`/sos/${sosId}/resolve`)
      loadAlerts()
    } catch (error) {
      alert('Erreur lors de la résolution')
    }
  }

  const getStatusColor = (status) => {
    const colors = {
      active: 'bg-red-100 text-red-800',
      resolved: 'bg-green-100 text-green-800',
      false_alarm: 'bg-yellow-100 text-yellow-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  const getStatusLabel = (status) => {
    const labels = {
      active: 'Active',
      resolved: 'Résolue',
      false_alarm: 'Fausse alerte'
    }
    return labels[status] || status
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Alertes SOS</h1>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg"
        >
          <option value="">Toutes</option>
          <option value="active">Actives</option>
          <option value="resolved">Résolues</option>
          <option value="false_alarm">Fausses alertes</option>
        </select>
      </div>

      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Utilisateur</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Position</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Course</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {alerts.map((alert) => (
              <tr key={alert.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 text-sm">
                  <div>
                    <p className="font-medium">{alert.user?.name || 'N/A'}</p>
                    <p className="text-gray-500 text-xs">{alert.user?.phoneNumber || ''}</p>
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {alert.location?.address || `${alert.location?.latitude?.toFixed(4)}, ${alert.location?.longitude?.toFixed(4)}`}
                </td>
                <td className="px-6 py-4 text-sm">
                  {alert.ride ? (
                    <span className="text-blue-600">Course #{alert.ride.id}</span>
                  ) : (
                    <span className="text-gray-400">-</span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(alert.status)}`}>
                    {getStatusLabel(alert.status)}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {format(new Date(alert.createdAt), 'dd/MM/yyyy HH:mm')}
                </td>
                <td className="px-6 py-4">
                  {alert.status === 'active' && (
                    <button
                      onClick={() => handleResolve(alert.id)}
                      className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 text-sm"
                    >
                      Résoudre
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {alerts.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucune alerte SOS trouvée
          </div>
        )}
      </div>
    </div>
  )
}

