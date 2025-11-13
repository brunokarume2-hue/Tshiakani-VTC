import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../services/api'

export default function Users() {
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('')

  useEffect(() => {
    loadUsers()
  }, [filter])

  const loadUsers = async () => {
    try {
      const params = filter ? `?role=${filter}` : ''
      const response = await api.get(`/users${params}`)
      setUsers(response.data.users)
    } catch (error) {
      console.error('Erreur chargement utilisateurs:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleBan = async (userId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir bannir cet utilisateur ?')) {
      return
    }

    try {
      await api.post(`/users/${userId}/ban`)
      loadUsers()
    } catch (error) {
      alert('Erreur lors du bannissement')
    }
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion des utilisateurs</h1>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg"
        >
          <option value="">Tous</option>
          <option value="client">Clients</option>
          <option value="driver">Conducteurs</option>
          <option value="admin">Admins</option>
        </select>
      </div>

      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Utilisateur</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rôle</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Informations</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div>
                    <p className="font-medium">{user.name}</p>
                    <p className="text-sm text-gray-500">{user.phoneNumber}</p>
                    {user.email && (
                      <p className="text-xs text-gray-400">{user.email}</p>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    user.role === 'driver' ? 'bg-orange-100 text-orange-800' :
                    user.role === 'admin' ? 'bg-red-100 text-red-800' :
                    'bg-green-100 text-green-800'
                  }`}>
                    {user.role === 'driver' ? 'Conducteur' :
                     user.role === 'admin' ? 'Admin' : 'Client'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  {user.role === 'driver' && (
                    <div className="space-y-1">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium block ${
                        user.driverInfo?.isOnline
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {user.driverInfo?.isOnline ? 'En ligne' : 'Hors ligne'}
                      </span>
                      {user.driverInfo?.documentsStatus === 'pending' && (
                        <span className="px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 block">
                          Documents en attente
                        </span>
                      )}
                    </div>
                  )}
                  {user.role !== 'driver' && (
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      user.isVerified
                        ? 'bg-green-100 text-green-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {user.isVerified ? 'Vérifié' : 'Non vérifié'}
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 text-sm text-gray-600">
                  {user.role === 'driver' && (
                    <div>
                      {user.driverInfo?.licensePlate && (
                        <p>Véhicule: {user.driverInfo.licensePlate}</p>
                      )}
                      {user.driverInfo?.vehicleType && (
                        <p className="text-xs">Type: {user.driverInfo.vehicleType}</p>
                      )}
                    </div>
                  )}
                  {user.role === 'client' && (
                    <p className="text-xs">Inscrit le {new Date(user.createdAt).toLocaleDateString('fr-FR')}</p>
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="flex gap-2">
                    {user.role === 'driver' && (
                      <button
                        onClick={() => navigate('/drivers')}
                        className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                      >
                        Voir détails
                      </button>
                    )}
                    {user.role === 'client' && (
                      <button
                        onClick={() => navigate('/clients')}
                        className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                      >
                        Voir détails
                      </button>
                    )}
                    {user.role !== 'admin' && (
                      <button
                        onClick={() => handleBan(user.id)}
                        className="px-3 py-1 bg-red-500 text-white rounded text-sm hover:bg-red-600"
                      >
                        Bannir
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {users.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucun utilisateur trouvé
          </div>
        )}
      </div>
    </div>
  )
}

