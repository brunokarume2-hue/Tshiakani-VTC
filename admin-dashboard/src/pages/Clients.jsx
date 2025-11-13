import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import api from '../services/api'

export default function Clients() {
  const [clients, setClients] = useState([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState({
    search: '',
    sortBy: 'recent'
  })
  const [selectedClient, setSelectedClient] = useState(null)
  const [showDetails, setShowDetails] = useState(false)

  useEffect(() => {
    loadClients()
  }, [filters])

  const loadClients = async () => {
    try {
      const params = new URLSearchParams()
      params.append('role', 'client')
      
      const response = await api.get(`/users?${params.toString()}`)
      let clientsList = response.data.users || []
      
      // Filtrer par recherche
      if (filters.search) {
        clientsList = clientsList.filter(client => 
          client.name.toLowerCase().includes(filters.search.toLowerCase()) ||
          client.phoneNumber.includes(filters.search)
        )
      }
      
      // Charger les statistiques pour chaque client
      const clientsWithStats = await Promise.all(
        clientsList.map(async (client) => {
          try {
            const statsResponse = await api.get(`/admin/clients/${client.id}/stats`)
            return { ...client, stats: statsResponse.data }
          } catch (error) {
            return { ...client, stats: null }
          }
        })
      )
      
      // Trier
      if (filters.sortBy === 'recent') {
        clientsWithStats.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      } else if (filters.sortBy === 'rides') {
        clientsWithStats.sort((a, b) => (b.stats?.totalRides || 0) - (a.stats?.totalRides || 0))
      } else if (filters.sortBy === 'spending') {
        clientsWithStats.sort((a, b) => (b.stats?.totalSpending || 0) - (a.stats?.totalSpending || 0))
      }
      
      setClients(clientsWithStats)
    } catch (error) {
      console.error('Erreur chargement clients:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleViewDetails = async (clientId) => {
    try {
      const response = await api.get(`/admin/clients/${clientId}`)
      setSelectedClient(response.data)
      setShowDetails(true)
    } catch (error) {
      console.error('Erreur chargement détails:', error)
      alert('Erreur lors du chargement des détails')
    }
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion des clients</h1>
      </div>

      {/* Filtres */}
      <div className="bg-white p-6 rounded-xl shadow">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Recherche</label>
            <input
              type="text"
              placeholder="Nom ou téléphone..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Trier par</label>
            <select
              value={filters.sortBy}
              onChange={(e) => setFilters({ ...filters, sortBy: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            >
              <option value="recent">Plus récents</option>
              <option value="rides">Plus de courses</option>
              <option value="spending">Plus de dépenses</option>
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={() => setFilters({ search: '', sortBy: 'recent' })}
              className="w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
            >
              Réinitialiser
            </button>
          </div>
        </div>
      </div>

      {/* Liste des clients */}
      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statistiques</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {clients.map((client) => (
              <tr key={client.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div>
                    <p className="font-medium">{client.name}</p>
                    <p className="text-sm text-gray-500">{client.phoneNumber}</p>
                    <p className="text-xs text-gray-400">
                      Inscrit le {format(new Date(client.createdAt), 'dd/MM/yyyy')}
                    </p>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    client.isVerified
                      ? 'bg-green-100 text-green-800'
                      : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {client.isVerified ? 'Vérifié' : 'Non vérifié'}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm">
                  {client.stats ? (
                    <div>
                      <p className="font-medium">{client.stats.totalRides || 0} courses</p>
                      <p className="text-gray-500">
                        {client.stats.totalSpending ? `${(client.stats.totalSpending / 1000).toFixed(0)}K CDF` : '0 CDF'} dépensés
                      </p>
                      <p className="text-gray-500">
                        Note moyenne donnée: {client.stats.averageRatingGiven ? client.stats.averageRatingGiven.toFixed(1) : 'N/A'}/5
                      </p>
                    </div>
                  ) : (
                    <span className="text-gray-400">Chargement...</span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <button
                    onClick={() => handleViewDetails(client.id)}
                    className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 text-sm"
                  >
                    Détails
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {clients.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucun client trouvé
          </div>
        )}
      </div>

      {/* Modal détails client */}
      {showDetails && selectedClient && (
        <ClientDetailsModal
          client={selectedClient}
          onClose={() => setShowDetails(false)}
        />
      )}
    </div>
  )
}

function ClientDetailsModal({ client, onClose }) {
  const [clientDetails, setClientDetails] = useState(client)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('info')

  useEffect(() => {
    loadFullDetails()
  }, [client.id])

  const loadFullDetails = async () => {
    try {
      const response = await api.get(`/admin/clients/${client.id}`)
      setClientDetails(response.data)
    } catch (error) {
      console.error('Erreur chargement détails:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-xl p-8 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
          <div className="text-center py-12">Chargement...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-5xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b">
          <div className="flex justify-between items-center">
            <h2 className="text-2xl font-bold text-gray-800">Détails du client</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 text-2xl"
            >
              ×
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b">
          <div className="flex space-x-4 px-6">
            {['info', 'stats', 'rides'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`py-4 px-2 border-b-2 ${
                  activeTab === tab
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500'
                }`}
              >
                {tab === 'info' && 'Informations'}
                {tab === 'stats' && 'Statistiques'}
                {tab === 'rides' && 'Historique'}
              </button>
            ))}
          </div>
        </div>

        <div className="p-6">
          {activeTab === 'info' && <ClientInfoTab client={clientDetails} />}
          {activeTab === 'stats' && <ClientStatsTab client={clientDetails} />}
          {activeTab === 'rides' && <ClientRidesTab clientId={clientDetails.id} />}
        </div>
      </div>
    </div>
  )
}

function ClientInfoTab({ client }) {
  return (
    <div className="grid grid-cols-2 gap-6">
      <div>
        <h3 className="font-semibold text-gray-700 mb-4">Informations personnelles</h3>
        <div className="space-y-3">
          <div>
            <p className="text-sm text-gray-500">Nom</p>
            <p className="font-medium">{client.name}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Téléphone</p>
            <p className="font-medium">{client.phoneNumber}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Email</p>
            <p className="font-medium">{client.email || 'Non renseigné'}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Date d'inscription</p>
            <p className="font-medium">
              {client.createdAt ? format(new Date(client.createdAt), 'dd/MM/yyyy') : 'N/A'}
            </p>
          </div>
        </div>
      </div>
      <div>
        <h3 className="font-semibold text-gray-700 mb-4">Statut</h3>
        <div className="space-y-3">
          <div>
            <p className="text-sm text-gray-500">Compte vérifié</p>
            <span className={`px-3 py-1 rounded-full text-xs font-medium ${
              client.isVerified
                ? 'bg-green-100 text-green-800'
                : 'bg-yellow-100 text-yellow-800'
            }`}>
              {client.isVerified ? 'Vérifié' : 'Non vérifié'}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

function ClientStatsTab({ client }) {
  const stats = client.stats || {}

  return (
    <div className="space-y-6">
      <h3 className="font-semibold text-gray-700 mb-4">Statistiques du client</h3>
      <div className="grid grid-cols-3 gap-6">
        <div className="bg-blue-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Courses totales</p>
          <p className="text-3xl font-bold text-blue-600">{stats.totalRides || 0}</p>
        </div>
        <div className="bg-green-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Dépenses totales</p>
          <p className="text-3xl font-bold text-green-600">
            {stats.totalSpending ? `${(stats.totalSpending / 1000).toFixed(0)}K CDF` : '0 CDF'}
          </p>
        </div>
        <div className="bg-orange-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Note moyenne donnée</p>
          <p className="text-3xl font-bold text-orange-600">
            {stats.averageRatingGiven ? stats.averageRatingGiven.toFixed(1) : 'N/A'}
          </p>
        </div>
        <div className="bg-purple-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Courses ce mois</p>
          <p className="text-3xl font-bold text-purple-600">{stats.monthlyRides || 0}</p>
        </div>
        <div className="bg-yellow-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Dépenses ce mois</p>
          <p className="text-3xl font-bold text-yellow-600">
            {stats.monthlySpending ? `${(stats.monthlySpending / 1000).toFixed(0)}K CDF` : '0 CDF'}
          </p>
        </div>
        <div className="bg-red-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Taux d'annulation</p>
          <p className="text-3xl font-bold text-red-600">
            {stats.cancellationRate ? `${stats.cancellationRate.toFixed(1)}%` : '0%'}
          </p>
        </div>
      </div>
    </div>
  )
}

function ClientRidesTab({ clientId }) {
  const [rides, setRides] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadRides()
  }, [clientId])

  const loadRides = async () => {
    try {
      const response = await api.get(`/admin/clients/${clientId}/rides`)
      setRides(response.data.rides || [])
    } catch (error) {
      console.error('Erreur chargement courses:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <div className="text-center py-8">Chargement...</div>

  return (
    <div className="space-y-4">
      <h3 className="font-semibold text-gray-700 mb-4">Historique des courses</h3>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">ID</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Conducteur</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Prix</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Note</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Statut</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {rides.map((ride) => (
              <tr key={ride.id}>
                <td className="px-4 py-2 text-sm">#{ride.id}</td>
                <td className="px-4 py-2 text-sm">{ride.driver?.name || 'N/A'}</td>
                <td className="px-4 py-2 text-sm font-semibold">{ride.finalPrice || ride.estimatedPrice} CDF</td>
                <td className="px-4 py-2 text-sm">
                  {ride.rating ? (
                    <span className="text-yellow-500">★ {ride.rating}/5</span>
                  ) : (
                    <span className="text-gray-400">Non noté</span>
                  )}
                </td>
                <td className="px-4 py-2">
                  <span className={`px-2 py-1 rounded text-xs ${
                    ride.status === 'completed' ? 'bg-green-100 text-green-800' :
                    ride.status === 'cancelled' ? 'bg-red-100 text-red-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {ride.status}
                  </span>
                </td>
                <td className="px-4 py-2 text-sm text-gray-500">
                  {format(new Date(ride.createdAt), 'dd/MM/yyyy HH:mm')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {rides.length === 0 && (
          <div className="text-center py-8 text-gray-500">Aucune course</div>
        )}
      </div>
    </div>
  )
}

