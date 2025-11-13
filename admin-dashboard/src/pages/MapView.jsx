import { useEffect, useState } from 'react'
import api from '../services/api'
import { io } from 'socket.io-client'

export default function MapView() {
  const [drivers, setDrivers] = useState([])
  const [activeRides, setActiveRides] = useState([])
  const [socket, setSocket] = useState(null)
  const [mapCenter, setMapCenter] = useState({ lat: -4.3276, lng: 15.3136 }) // Kinshasa par défaut
  const [mapZoom, setMapZoom] = useState(12)

  useEffect(() => {
    loadData()
    
    // Connexion Socket.io
    const socketUrl = import.meta.env.VITE_SOCKET_URL || 'http://localhost:3000'
    const newSocket = io(socketUrl)
    setSocket(newSocket)

    newSocket.on('driver:location:update', (data) => {
      setDrivers(prev => prev.map(driver => 
        driver.id === data.driverId
          ? { ...driver, location: data.location }
          : driver
      ))
    })

    // Interroger toutes les 10 secondes
    const interval = setInterval(() => {
      loadData()
    }, 10000)

    return () => {
      newSocket.close()
      clearInterval(interval)
    }
  }, [])

  const loadData = async () => {
    try {
      // Charger les chauffeurs disponibles (nouvel endpoint)
      const driversResponse = await api.get('/admin/available_drivers')
      setDrivers(driversResponse.data)

      // Charger les courses actives (nouvel endpoint)
      const ridesResponse = await api.get('/admin/active_rides')
      setActiveRides(ridesResponse.data)
    } catch (error) {
      console.error('Erreur chargement données:', error)
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'disponible':
        return 'bg-green-500'
      case 'en_course':
        return 'bg-red-500'
      default:
        return 'bg-gray-500'
    }
  }

  const getStatusText = (status) => {
    switch (status) {
      case 'disponible':
        return 'Disponible'
      case 'en_course':
        return 'En course'
      default:
        return 'Hors ligne'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Surveillance en temps réel</h1>
        <div className="flex gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-500 rounded-full"></div>
            <span>Disponible</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-500 rounded-full"></div>
            <span>En course</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Carte interactive avec OpenStreetMap */}
        <div className="lg:col-span-2 bg-white rounded-xl shadow p-6">
          <h2 className="text-lg font-semibold mb-4">Carte des chauffeurs</h2>
          <div className="bg-gray-100 rounded-lg h-[600px] relative overflow-hidden">
            {/* Carte OpenStreetMap intégrée via iframe */}
            <iframe
              width="100%"
              height="100%"
              frameBorder="0"
              scrolling="no"
              marginHeight="0"
              marginWidth="0"
              src={`https://www.openstreetmap.org/export/embed.html?bbox=${mapCenter.lng - 0.1},${mapCenter.lat - 0.1},${mapCenter.lng + 0.1},${mapCenter.lat + 0.1}&layer=mapnik&marker=${mapCenter.lat},${mapCenter.lng}`}
              style={{ border: 0 }}
            ></iframe>
            
            {/* Légende des marqueurs */}
            <div className="absolute top-4 right-4 bg-white rounded-lg shadow-lg p-4 z-10">
              <h3 className="font-semibold mb-2 text-sm">Légende</h3>
              <div className="space-y-2 text-xs">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                  <span>Chauffeur disponible ({drivers.filter(d => d.status === 'disponible').length})</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                  <span>Chauffeur en course ({drivers.filter(d => d.status === 'en_course').length})</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                  <span>Courses actives ({activeRides.length})</span>
                </div>
              </div>
            </div>
          </div>
          
          {/* Statistiques sous la carte */}
          <div className="grid grid-cols-3 gap-4 mt-4">
            <div className="bg-green-50 rounded-lg p-4">
              <p className="text-2xl font-bold text-green-600">
                {drivers.filter(d => d.status === 'disponible').length}
              </p>
              <p className="text-sm text-gray-600">Disponibles</p>
            </div>
            <div className="bg-red-50 rounded-lg p-4">
              <p className="text-2xl font-bold text-red-600">
                {drivers.filter(d => d.status === 'en_course').length}
              </p>
              <p className="text-sm text-gray-600">En course</p>
            </div>
            <div className="bg-blue-50 rounded-lg p-4">
              <p className="text-2xl font-bold text-blue-600">
                {activeRides.length}
              </p>
              <p className="text-sm text-gray-600">Courses actives</p>
            </div>
          </div>
        </div>

        {/* Panneaux latéraux */}
        <div className="space-y-4">
          {/* Liste des chauffeurs */}
          <div className="bg-white rounded-xl shadow p-6 max-h-[400px] overflow-y-auto">
            <h2 className="text-lg font-semibold mb-4">Chauffeurs en ligne</h2>
            <div className="space-y-3">
              {drivers.map((driver) => (
                <div key={driver.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition">
                  <div className={`w-10 h-10 ${getStatusColor(driver.status)} rounded-full flex items-center justify-center text-white font-bold`}>
                    {driver.name?.[0] || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">{driver.name || 'Chauffeur'}</p>
                    <p className="text-xs text-gray-500">
                      {getStatusText(driver.status)}
                    </p>
                    {driver.location && (
                      <p className="text-xs text-gray-400 truncate">
                        {driver.location.latitude.toFixed(4)}, {driver.location.longitude.toFixed(4)}
                      </p>
                    )}
                  </div>
                  <div className={`w-3 h-3 ${getStatusColor(driver.status)} rounded-full`}></div>
                </div>
              ))}
              {drivers.length === 0 && (
                <p className="text-gray-500 text-center py-4">Aucun chauffeur en ligne</p>
              )}
            </div>
          </div>

          {/* Tableau d'audit des courses actives */}
          <div className="bg-white rounded-xl shadow p-6 max-h-[400px] overflow-y-auto">
            <h2 className="text-lg font-semibold mb-4">Courses actives</h2>
            <div className="space-y-3">
              {activeRides.map((ride) => (
                <div key={ride.id} className="p-3 bg-blue-50 rounded-lg border-l-4 border-blue-500">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <p className="font-medium text-sm">{ride.client?.name || 'Client'}</p>
                      <p className="text-xs text-gray-500">{ride.client?.phoneNumber || ''}</p>
                    </div>
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${
                      ride.status === 'accepted' ? 'bg-green-100 text-green-700' :
                      ride.status === 'in_progress' ? 'bg-blue-100 text-blue-700' :
                      'bg-yellow-100 text-yellow-700'
                    }`}>
                      {ride.status}
                    </span>
                  </div>
                  {ride.driver && (
                    <p className="text-xs text-gray-600 mb-1">
                      Chauffeur: {ride.driver.name}
                    </p>
                  )}
                  <p className="text-xs text-gray-500 truncate">
                    {ride.pickupAddress || 'Départ'} → {ride.dropoffAddress || 'Destination'}
                  </p>
                  {ride.estimatedPrice && (
                    <p className="text-xs font-semibold text-blue-600 mt-1">
                      {ride.estimatedPrice.toFixed(0)} FC
                    </p>
                  )}
                </div>
              ))}
              {activeRides.length === 0 && (
                <p className="text-gray-500 text-center py-4">Aucune course active</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

