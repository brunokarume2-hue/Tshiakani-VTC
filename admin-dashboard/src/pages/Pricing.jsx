import { useEffect, useState } from 'react'
import api from '../services/api'

export default function Pricing() {
  const [pricing, setPricing] = useState({
    basePrice: 1000,
    pricePerKm: 500,
    pricePerMinute: 100,
    minimumPrice: 1500,
    surgeMultiplier: 1.5,
    nightSurcharge: 0.2,
    vehicleTypes: {
      standard: { multiplier: 1.0, name: 'Standard' },
      premium: { multiplier: 1.5, name: 'Premium' },
      luxury: { multiplier: 2.0, name: 'Luxury' }
    }
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    loadPricing()
  }, [])

  const loadPricing = async () => {
    try {
      const response = await api.get('/admin/pricing')
      if (response?.data) {
        setPricing(response.data)
      }
    } catch (error) {
      console.error('Erreur chargement tarification:', error)
      // En cas d'erreur, garder les valeurs par défaut
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    setSaving(true)
    setMessage('')
    
    try {
      await api.post('/admin/pricing', pricing)
      setMessage('Tarification mise à jour avec succès')
      setTimeout(() => setMessage(''), 3000)
    } catch (error) {
      setMessage('Erreur lors de la mise à jour')
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  const handleChange = (field, value) => {
    setPricing(prev => ({
      ...prev,
      [field]: parseFloat(value) || 0
    }))
  }

  const handleVehicleTypeChange = (type, field, value) => {
    setPricing(prev => ({
      ...prev,
      vehicleTypes: {
        ...prev.vehicleTypes,
        [type]: {
          ...prev.vehicleTypes[type],
          [field]: field === 'multiplier' ? parseFloat(value) || 1 : value
        }
      }
    }))
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion de la tarification</h1>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold disabled:opacity-50"
        >
          {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
        </button>
      </div>

      {message && (
        <div className={`p-4 rounded-lg ${
          message.includes('succès') 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message}
        </div>
      )}

      {/* Tarifs de base */}
      <div className="bg-white rounded-xl shadow p-6">
        <h2 className="text-xl font-semibold mb-6 text-gray-800">Tarifs de base</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Prix de base (CDF)
            </label>
            <input
              type="number"
              value={pricing.basePrice}
              onChange={(e) => handleChange('basePrice', e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="0"
              step="100"
            />
            <p className="text-xs text-gray-500 mt-1">Prix fixe au démarrage de la course</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Prix par kilomètre (CDF)
            </label>
            <input
              type="number"
              value={pricing.pricePerKm}
              onChange={(e) => handleChange('pricePerKm', e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="0"
              step="50"
            />
            <p className="text-xs text-gray-500 mt-1">Coût par kilomètre parcouru</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Prix par minute (CDF)
            </label>
            <input
              type="number"
              value={pricing.pricePerMinute}
              onChange={(e) => handleChange('pricePerMinute', e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="0"
              step="10"
            />
            <p className="text-xs text-gray-500 mt-1">Coût par minute de trajet</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Prix minimum (CDF)
            </label>
            <input
              type="number"
              value={pricing.minimumPrice}
              onChange={(e) => handleChange('minimumPrice', e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="0"
              step="100"
            />
            <p className="text-xs text-gray-500 mt-1">Prix minimum garanti pour une course</p>
          </div>
        </div>
      </div>

      {/* Surfactures */}
      <div className="bg-white rounded-xl shadow p-6">
        <h2 className="text-xl font-semibold mb-6 text-gray-800">Surfactures</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Multiplicateur de pic (surge)
            </label>
            <input
              type="number"
              value={pricing.surgeMultiplier}
              onChange={(e) => handleChange('surgeMultiplier', e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="1"
              max="3"
              step="0.1"
            />
            <p className="text-xs text-gray-500 mt-1">Multiplicateur appliqué en période de forte demande</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Surfacture nocturne (%)
            </label>
            <input
              type="number"
              value={pricing.nightSurcharge * 100}
              onChange={(e) => handleChange('nightSurcharge', (parseFloat(e.target.value) || 0) / 100)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              min="0"
              max="100"
              step="5"
            />
            <p className="text-xs text-gray-500 mt-1">Pourcentage ajouté aux courses de nuit (22h-6h)</p>
          </div>
        </div>
      </div>

      {/* Types de véhicules */}
      <div className="bg-white rounded-xl shadow p-6">
        <h2 className="text-xl font-semibold mb-6 text-gray-800">Tarifs par type de véhicule</h2>
        <div className="space-y-4">
          {Object.entries(pricing.vehicleTypes).map(([type, config]) => (
            <div key={type} className="border rounded-lg p-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nom du type
                  </label>
                  <input
                    type="text"
                    value={config.name}
                    onChange={(e) => handleVehicleTypeChange(type, 'name', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Multiplicateur
                  </label>
                  <input
                    type="number"
                    value={config.multiplier}
                    onChange={(e) => handleVehicleTypeChange(type, 'multiplier', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                    min="0.5"
                    max="5"
                    step="0.1"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Prix de base × {config.multiplier} = {pricing.basePrice * config.multiplier} CDF
                  </p>
                </div>
                <div className="flex items-end">
                  <div className="w-full bg-gray-50 p-3 rounded-lg">
                    <p className="text-sm text-gray-600">Exemple de course</p>
                    <p className="text-lg font-semibold text-gray-800">
                      {Math.max(
                        pricing.minimumPrice * config.multiplier,
                        (pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)) * config.multiplier
                      ).toFixed(0)} CDF
                    </p>
                    <p className="text-xs text-gray-500">(5 km, 10 min)</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Aperçu de calcul */}
      <div className="bg-white rounded-xl shadow p-6">
        <h2 className="text-xl font-semibold mb-6 text-gray-800">Aperçu de calcul</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-blue-50 p-4 rounded-lg">
            <h3 className="font-semibold text-gray-700 mb-3">Course standard (5 km, 10 min)</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Prix de base:</span>
                <span className="font-medium">{pricing.basePrice} CDF</span>
              </div>
              <div className="flex justify-between">
                <span>Distance (5 km):</span>
                <span className="font-medium">{5 * pricing.pricePerKm} CDF</span>
              </div>
              <div className="flex justify-between">
                <span>Durée (10 min):</span>
                <span className="font-medium">{10 * pricing.pricePerMinute} CDF</span>
              </div>
              <div className="border-t pt-2 mt-2">
                <div className="flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span className="text-green-600">
                    {Math.max(
                      pricing.minimumPrice,
                      pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)
                    )} CDF
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-green-50 p-4 rounded-lg">
            <h3 className="font-semibold text-gray-700 mb-3">Course premium (5 km, 10 min)</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Prix standard:</span>
                <span className="font-medium">
                  {Math.max(
                    pricing.minimumPrice,
                    pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)
                  )} CDF
                </span>
              </div>
              <div className="flex justify-between">
                <span>Multiplicateur ({pricing.vehicleTypes.premium.multiplier}x):</span>
                <span className="font-medium">
                  × {pricing.vehicleTypes.premium.multiplier}
                </span>
              </div>
              <div className="border-t pt-2 mt-2">
                <div className="flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span className="text-green-600">
                    {Math.max(
                      pricing.minimumPrice * pricing.vehicleTypes.premium.multiplier,
                      (pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)) * pricing.vehicleTypes.premium.multiplier
                    ).toFixed(0)} CDF
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-purple-50 p-4 rounded-lg">
            <h3 className="font-semibold text-gray-700 mb-3">Avec pic de demande</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Prix standard:</span>
                <span className="font-medium">
                  {Math.max(
                    pricing.minimumPrice,
                    pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)
                  )} CDF
                </span>
              </div>
              <div className="flex justify-between">
                <span>Surge ({pricing.surgeMultiplier}x):</span>
                <span className="font-medium">
                  × {pricing.surgeMultiplier}
                </span>
              </div>
              <div className="border-t pt-2 mt-2">
                <div className="flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span className="text-green-600">
                    {Math.max(
                      pricing.minimumPrice,
                      pricing.basePrice + (5 * pricing.pricePerKm) + (10 * pricing.pricePerMinute)
                    ) * pricing.surgeMultiplier} CDF
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
