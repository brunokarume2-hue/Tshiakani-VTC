import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import api from '../services/api'

export default function Drivers() {
  const [drivers, setDrivers] = useState([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState({
    status: '',
    search: ''
  })
  const [selectedDriver, setSelectedDriver] = useState(null)
  const [showDetails, setShowDetails] = useState(false)

  useEffect(() => {
    loadDrivers()
  }, [filters])

  const loadDrivers = async () => {
    try {
      const params = new URLSearchParams()
      params.append('role', 'driver')
      if (filters.status) params.append('status', filters.status)
      
      const response = await api.get(`/users?${params.toString()}`)
      let driversList = response.data.users || []
      
      // Filtrer par recherche
      if (filters.search) {
        driversList = driversList.filter(driver => 
          driver.name.toLowerCase().includes(filters.search.toLowerCase()) ||
          driver.phoneNumber.includes(filters.search)
        )
      }
      
      // Charger les statistiques pour chaque conducteur
      const driversWithStats = await Promise.all(
        driversList.map(async (driver) => {
          try {
            const statsResponse = await api.get(`/admin/drivers/${driver.id}/stats`)
            return { ...driver, stats: statsResponse.data }
          } catch (error) {
            return { ...driver, stats: null }
          }
        })
      )
      
      setDrivers(driversWithStats)
    } catch (error) {
      console.error('Erreur chargement conducteurs:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleViewDetails = async (driverId) => {
    try {
      const response = await api.get(`/admin/drivers/${driverId}`)
      setSelectedDriver(response.data)
      setShowDetails(true)
    } catch (error) {
      console.error('Erreur chargement détails:', error)
      alert('Erreur lors du chargement des détails')
    }
  }

  const handleValidateDocuments = async (driverId) => {
    if (!window.confirm('Valider les documents de ce conducteur ?')) return
    
    try {
      await api.post(`/admin/drivers/${driverId}/validate-documents`)
      loadDrivers()
      alert('Documents validés avec succès')
    } catch (error) {
      alert('Erreur lors de la validation')
    }
  }

  const handleToggleStatus = async (driverId, currentStatus) => {
    const action = currentStatus ? 'désactiver' : 'activer'
    if (!window.confirm(`Êtes-vous sûr de vouloir ${action} ce conducteur ?`)) return
    
    try {
      await api.patch(`/admin/drivers/${driverId}/status`, { 
        isActive: !currentStatus 
      })
      loadDrivers()
    } catch (error) {
      alert('Erreur lors de la mise à jour')
    }
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion des conducteurs</h1>
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
            <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
            <select
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
            >
              <option value="">Tous</option>
              <option value="online">En ligne</option>
              <option value="offline">Hors ligne</option>
              <option value="pending">En attente validation</option>
              <option value="active">Actifs</option>
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={() => setFilters({ status: '', search: '' })}
              className="w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
            >
              Réinitialiser
            </button>
          </div>
        </div>
      </div>

      {/* Liste des conducteurs */}
      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conducteur</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Véhicule</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statistiques</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {drivers.map((driver) => (
              <tr key={driver.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div>
                    <p className="font-medium">{driver.name}</p>
                    <p className="text-sm text-gray-500">{driver.phoneNumber}</p>
                  </div>
                </td>
                <td className="px-6 py-4 text-sm">
                  {driver.driverInfo?.licensePlate ? (
                    <div>
                      <p className="font-medium">{driver.driverInfo.licensePlate}</p>
                      <p className="text-gray-500 text-xs">
                        {driver.driverInfo.vehicleType || 'Non spécifié'}
                      </p>
                    </div>
                  ) : (
                    <span className="text-gray-400">Non renseigné</span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="space-y-1">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      driver.driverInfo?.isOnline
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {driver.driverInfo?.isOnline ? 'En ligne' : 'Hors ligne'}
                    </span>
                    {driver.driverInfo?.documentsStatus === 'pending' && (
                      <span className="block px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        Documents en attente
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm">
                  {driver.stats ? (
                    <div>
                      <p className="font-medium">{driver.stats.totalRides || 0} courses</p>
                      <p className="text-gray-500">
                        Note: {driver.stats.averageRating ? driver.stats.averageRating.toFixed(1) : 'N/A'}/5
                      </p>
                      <p className="text-green-600 font-semibold">
                        {driver.stats.totalEarnings ? `${(driver.stats.totalEarnings / 1000).toFixed(0)}K CDF` : '0 CDF'}
                      </p>
                    </div>
                  ) : (
                    <span className="text-gray-400">Chargement...</span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleViewDetails(driver.id)}
                      className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                    >
                      Détails
                    </button>
                    {driver.driverInfo?.documentsStatus === 'pending' && (
                      <button
                        onClick={() => handleValidateDocuments(driver.id)}
                        className="px-3 py-1 bg-green-500 text-white rounded text-sm hover:bg-green-600"
                      >
                        Valider
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {drivers.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucun conducteur trouvé
          </div>
        )}
      </div>

      {/* Modal détails conducteur */}
      {showDetails && selectedDriver && (
        <DriverDetailsModal
          driver={selectedDriver}
          onClose={() => setShowDetails(false)}
          onUpdate={loadDrivers}
        />
      )}
    </div>
  )
}

function DriverDetailsModal({ driver, onClose, onUpdate }) {
  const [driverDetails, setDriverDetails] = useState(driver)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('info')

  useEffect(() => {
    loadFullDetails()
  }, [driver.id])

  const loadFullDetails = async () => {
    try {
      const response = await api.get(`/admin/drivers/${driver.id}`)
      setDriverDetails(response.data)
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
            <h2 className="text-2xl font-bold text-gray-800">
              Détails du conducteur
            </h2>
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
            {['info', 'documents', 'vehicle', 'stats', 'rides'].map((tab) => (
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
                {tab === 'documents' && 'Documents'}
                {tab === 'vehicle' && 'Véhicule'}
                {tab === 'stats' && 'Statistiques'}
                {tab === 'rides' && 'Courses'}
              </button>
            ))}
          </div>
        </div>

        <div className="p-6">
          {activeTab === 'info' && (
            <DriverInfoTab driver={driverDetails} onUpdate={loadFullDetails} />
          )}
          {activeTab === 'documents' && (
            <DriverDocumentsTab driver={driverDetails} onUpdate={loadFullDetails} />
          )}
          {activeTab === 'vehicle' && (
            <DriverVehicleTab driver={driverDetails} onUpdate={loadFullDetails} />
          )}
          {activeTab === 'stats' && (
            <DriverStatsTab driver={driverDetails} />
          )}
          {activeTab === 'rides' && (
            <DriverRidesTab driverId={driverDetails.id} />
          )}
        </div>
      </div>
    </div>
  )
}

function DriverInfoTab({ driver, onUpdate }) {
  const [formData, setFormData] = useState({
    name: driver.name || '',
    phoneNumber: driver.phoneNumber || '',
    email: driver.email || '',
    isVerified: driver.isVerified || false
  })
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  const handleChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: field === 'isVerified' ? value : value
    }))
  }

  const handleSave = async () => {
    setSaving(true)
    setMessage('')
    
    try {
      await api.patch(`/admin/drivers/${driver.id}`, formData)
      setMessage('Informations mises à jour avec succès')
      setTimeout(() => setMessage(''), 3000)
      if (onUpdate) onUpdate()
    } catch (error) {
      setMessage('Erreur lors de la mise à jour')
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <div className={`p-4 rounded-lg ${
          message.includes('succès') 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message}
        </div>
      )}

      <div className="flex justify-between items-center mb-4">
        <h3 className="font-semibold text-gray-700">Informations personnelles</h3>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold disabled:opacity-50"
        >
          {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
        </button>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Nom</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => handleChange('name', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Téléphone</label>
              <input
                type="tel"
                value={formData.phoneNumber}
                onChange={(e) => handleChange('phoneNumber', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => handleChange('email', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                placeholder="Non renseigné"
              />
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-2">Date d'inscription</p>
              <p className="font-medium text-gray-700">
                {driver.createdAt ? format(new Date(driver.createdAt), 'dd/MM/yyyy') : 'N/A'}
              </p>
            </div>
          </div>
        </div>
        <div>
          <h3 className="font-semibold text-gray-700 mb-4">Statut</h3>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-gray-500 mb-2">Statut en ligne</p>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                driver.driverInfo?.isOnline
                  ? 'bg-green-100 text-green-800'
                  : 'bg-gray-100 text-gray-800'
              }`}>
                {driver.driverInfo?.isOnline ? 'En ligne' : 'Hors ligne'}
              </span>
            </div>
            <div>
              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={formData.isVerified}
                  onChange={(e) => handleChange('isVerified', e.target.checked)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="text-sm font-medium text-gray-700">Compte vérifié</span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function DriverDocumentsTab({ driver, onUpdate }) {
  const handleValidate = async (documentType) => {
    try {
      await api.post(`/admin/drivers/${driver.id}/validate-document`, {
        documentType
      })
      onUpdate()
      alert('Document validé')
    } catch (error) {
      alert('Erreur lors de la validation')
    }
  }

  const handleReject = async (documentType) => {
    if (!window.confirm('Êtes-vous sûr de vouloir rejeter ce document ?')) return
    
    try {
      await api.post(`/admin/drivers/${driver.id}/reject-document`, {
        documentType
      })
      onUpdate()
      alert('Document rejeté')
    } catch (error) {
      alert('Erreur lors du rejet')
    }
  }

  const documents = driver.driverInfo?.documents || {}

  return (
    <div className="space-y-4">
      <h3 className="font-semibold text-gray-700 mb-4">Documents du conducteur</h3>
      {[
        { key: 'license', label: 'Permis de conduire', required: true },
        { key: 'insurance', label: 'Assurance', required: true },
        { key: 'registration', label: 'Carte grise', required: true },
        { key: 'identity', label: 'Pièce d\'identité', required: true }
      ].map((doc) => {
        const document = documents[doc.key]
        const status = document?.status || 'missing'
        
        return (
          <div key={doc.key} className="border rounded-lg p-4">
            <div className="flex justify-between items-center">
              <div>
                <p className="font-medium">{doc.label}</p>
                <p className="text-sm text-gray-500">
                  {status === 'validated' && 'Validé'}
                  {status === 'pending' && 'En attente'}
                  {status === 'rejected' && 'Rejeté'}
                  {status === 'missing' && 'Manquant'}
                </p>
                {document?.uploadedAt && (
                  <p className="text-xs text-gray-400">
                    Uploadé le {format(new Date(document.uploadedAt), 'dd/MM/yyyy')}
                  </p>
                )}
              </div>
              <div>
                {status === 'pending' && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleValidate(doc.key)}
                      className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
                    >
                      Valider
                    </button>
                    <button
                      onClick={() => handleReject(doc.key)}
                      className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
                    >
                      Rejeter
                    </button>
                  </div>
                )}
                {status === 'validated' && (
                  <span className="px-3 py-1 bg-green-100 text-green-800 rounded text-sm">
                    ✓ Validé
                  </span>
                )}
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}

function DriverVehicleTab({ driver, onUpdate }) {
  const vehicle = driver.driverInfo?.vehicle || {}
  const [formData, setFormData] = useState({
    licensePlate: driver.driverInfo?.licensePlate || vehicle.licensePlate || '',
    vehicleType: driver.driverInfo?.vehicleType || vehicle.type || '',
    brand: vehicle.brand || '',
    model: vehicle.model || '',
    year: vehicle.year || '',
    color: vehicle.color || ''
  })
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  const handleChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  const handleSave = async () => {
    setSaving(true)
    setMessage('')
    
    try {
      await api.patch(`/admin/drivers/${driver.id}/vehicle`, formData)
      setMessage('Informations du véhicule mises à jour avec succès')
      setTimeout(() => setMessage(''), 3000)
      if (onUpdate) onUpdate()
    } catch (error) {
      setMessage('Erreur lors de la mise à jour')
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <div className={`p-4 rounded-lg ${
          message.includes('succès') 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message}
        </div>
      )}

      <div className="flex justify-between items-center mb-4">
        <h3 className="font-semibold text-gray-700">Informations du véhicule</h3>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold disabled:opacity-50"
        >
          {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
        </button>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Immatriculation</label>
          <input
            type="text"
            value={formData.licensePlate}
            onChange={(e) => handleChange('licensePlate', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="ABC-123-DEF"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Type de véhicule</label>
          <select
            value={formData.vehicleType}
            onChange={(e) => handleChange('vehicleType', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
          >
            <option value="">Sélectionner...</option>
            <option value="standard">Standard</option>
            <option value="premium">Premium</option>
            <option value="luxury">Luxury</option>
            <option value="suv">SUV</option>
            <option value="van">Van</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Marque</label>
          <input
            type="text"
            value={formData.brand}
            onChange={(e) => handleChange('brand', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="Toyota, Honda, etc."
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Modèle</label>
          <input
            type="text"
            value={formData.model}
            onChange={(e) => handleChange('model', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="Corolla, Civic, etc."
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Année</label>
          <input
            type="number"
            value={formData.year}
            onChange={(e) => handleChange('year', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="2020"
            min="1900"
            max={new Date().getFullYear() + 1}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Couleur</label>
          <input
            type="text"
            value={formData.color}
            onChange={(e) => handleChange('color', e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="Noir, Blanc, etc."
          />
        </div>
      </div>
    </div>
  )
}

function DriverStatsTab({ driver }) {
  const stats = driver.stats || {}

  return (
    <div className="space-y-6">
      <h3 className="font-semibold text-gray-700 mb-4">Statistiques du conducteur</h3>
      <div className="grid grid-cols-3 gap-6">
        <div className="bg-blue-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Courses totales</p>
          <p className="text-3xl font-bold text-blue-600">{stats.totalRides || 0}</p>
        </div>
        <div className="bg-green-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Note moyenne</p>
          <p className="text-3xl font-bold text-green-600">
            {stats.averageRating ? stats.averageRating.toFixed(1) : 'N/A'}
          </p>
        </div>
        <div className="bg-orange-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Revenus totaux</p>
          <p className="text-3xl font-bold text-orange-600">
            {stats.totalEarnings ? `${(stats.totalEarnings / 1000).toFixed(0)}K CDF` : '0 CDF'}
          </p>
        </div>
        <div className="bg-purple-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Courses ce mois</p>
          <p className="text-3xl font-bold text-purple-600">{stats.monthlyRides || 0}</p>
        </div>
        <div className="bg-yellow-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Revenus ce mois</p>
          <p className="text-3xl font-bold text-yellow-600">
            {stats.monthlyEarnings ? `${(stats.monthlyEarnings / 1000).toFixed(0)}K CDF` : '0 CDF'}
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

function DriverRidesTab({ driverId }) {
  const [rides, setRides] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadRides()
  }, [driverId])

  const loadRides = async () => {
    try {
      const response = await api.get(`/admin/drivers/${driverId}/rides`)
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
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Client</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Prix</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Statut</th>
              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {rides.map((ride) => (
              <tr key={ride.id}>
                <td className="px-4 py-2 text-sm">#{ride.id}</td>
                <td className="px-4 py-2 text-sm">{ride.client?.name || 'N/A'}</td>
                <td className="px-4 py-2 text-sm font-semibold">{ride.finalPrice || ride.estimatedPrice} CDF</td>
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


